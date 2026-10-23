#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
dmm2xm GUI - a Tkinter front-end for the Python dmm2xm converter (Doom2D DMM
<-> XM / IT / S3M / MOD tracker modules).

Four tabs:
  1) "Пакетная конвертация (WAD)"  - reproduces conv_wad.bat: converts every
     song from doom2d.wad with its own quantization value. The song list and
     quantization values are pre-filled exactly like conv_wad.bat, but every
     field is editable, and songs can be added/removed/(de)selected.
  2) "Пакетная конвертация (папка .dmm)" - reproduces conv_dmm.bat: the same
     for a folder of already extracted .dmm files.
  3) "Один файл (DMM/WAD -> XM)"   - exposes every command-line switch of the
     original dmm2xm.exe (-q, -r, -o, -f, -m, -b) as GUI fields, for converting
     a single .dmm file or a single song out of a .wad file.
  4) "Обратно (XM/IT/S3M/MOD -> DMM)" - backward conversion to DMM + DMI, with
     channel selection, volume-change mode, sample offsets and subsong split.

A shared log panel at the bottom shows the converter's messages (the ones of
the original console tool plus the many added by the backward conversion).
"""

import os
import queue
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

from dmm2xm_convert import (
    ForwardOptions, convert_forward, convert_backward, ConversionError,
)
from dmm2xm_core import list_dmm_in_wad, get_extension, cut_extension, WadFile


# Default song list + quantization values, transcribed 1:1 from conv_wad.bat
DEFAULT_BATCH_SONGS = [
    ("ALLRIGHT", 8),
    ("BEST", 6),
    ("GLAD", 8),
    ("MENU", 22),
    ("INTERMUS", 16),
    ("SUPER", 12),
    ("АС", 8),
    ("АТАС", 12),
    ("АЙОЙ", 8),
    ("БОЖ_МУЗ", 8),
    ("БЫСТРОТА", 12),
    ("С_ВЫШАК", 8),
    ("КЛАСС", 8),
    ("ДУШЕВНАЯ", 8),
    ("ХЕХЕХЕ", 16),
    ("ХОХОХО", 8),
    ("КОНЕЦ", 10),
    ("МОЩЬ", 8),
    ("ПАЛАТА#6", 8),
    ("ПРИКОЛ", 8),
    ("ПРОБА", 8),
    ("ПРОСТОТА", 8),
    ("СОЛО", 8),
    ("СПОК", 12),
    ("СТРАХ", 8),
    ("ТИШЬ", 12),
    ("ТЫ_ПОБЕД", 8),
    ("ТЫ_ТРУП", 16),
    ("УЖАС", 12),
    ("ВЗБУЧКА", 12),
]


class LogPanel(ttk.Frame):
    def __init__(self, master):
        super().__init__(master)
        self.text = tk.Text(self, height=12, wrap="word", state="disabled",
                             background="#111318", foreground="#d7dee8",
                             insertbackground="#d7dee8", font=("Consolas", 9))
        yscroll = ttk.Scrollbar(self, orient="vertical", command=self.text.yview)
        self.text.configure(yscrollcommand=yscroll.set)
        self.text.grid(row=0, column=0, sticky="nsew")
        yscroll.grid(row=0, column=1, sticky="ns")
        self.grid_rowconfigure(0, weight=1)
        self.grid_columnconfigure(0, weight=1)
        self.queue = queue.Queue()
        self.after(80, self._poll)

    def log(self, msg):
        self.queue.put(msg)

    def clear(self):
        self.text.configure(state="normal")
        self.text.delete("1.0", "end")
        self.text.configure(state="disabled")

    def _poll(self):
        drained = False
        while True:
            try:
                msg = self.queue.get_nowait()
            except queue.Empty:
                break
            drained = True
            self.text.configure(state="normal")
            self.text.insert("end", msg)
            self.text.configure(state="disabled")
        if drained:
            self.text.see("end")
            # Force an immediate repaint instead of waiting for Tk's own idle
            # scheduling - keeps the log visibly "live" even while a CPU-heavy
            # background conversion thread is competing for the GIL.
            self.text.update_idletasks()
        self.after(50, self._poll)


def browse_open(entry, filetypes, initialdir=None):
    path = filedialog.askopenfilename(filetypes=filetypes, initialdir=initialdir)
    if path:
        entry.delete(0, "end")
        entry.insert(0, path)


def browse_save(entry, filetypes, defaultextension=""):
    path = filedialog.asksaveasfilename(filetypes=filetypes, defaultextension=defaultextension)
    if path:
        entry.delete(0, "end")
        entry.insert(0, path)


def browse_dir(entry):
    path = filedialog.askdirectory()
    if path:
        entry.delete(0, "end")
        entry.insert(0, path)


class _SongBatchTabBase(ttk.Frame):
    """Shared song-list/progress-bar machinery for both batch-conversion tabs
    (straight from a .wad, or from a folder of already-extracted .dmm files).
    Subclasses provide the source picker widgets and how to build the actual
    ForwardOptions/input path for each job."""

    #: Text shown on the "convert all" button while idle / while running.
    run_button_idle_text = "Конвертировать всё"
    run_button_busy_text = "Идёт конвертация..."
    #: Whether to show the "Список песен из WAD" helper button.
    show_list_songs_button = False

    def __init__(self, master, log_panel: LogPanel):
        super().__init__(master, padding=10)
        self.log_panel = log_panel
        self.rows = []  # list of dicts: enabled(BooleanVar), name(StringVar), quant(StringVar)
        self._status_queue = queue.Queue()
        self._running = False

        self._build_source_frame()
        self._build_common_options()
        self._build_table()
        self._build_buttons()

        self.after(50, self._poll_status)

    # --- hooks subclasses must/may override -----------------------------

    def _build_source_frame(self):
        """Build whatever file/folder pickers this variant needs, at the top
        of the tab. Must be implemented by subclasses."""
        raise NotImplementedError

    def _list_songs(self):
        """Only used when show_list_songs_button is True."""
        raise NotImplementedError

    def _resolve_output_dir(self):
        """Returns the effective output directory."""
        raise NotImplementedError

    def _prepare_jobs(self, jobs):
        """Called once, on the worker thread, before iterating jobs. Returns
        an extra context object passed to _make_options() for each job, or
        raises an exception (caught by the caller) to abort the whole batch
        with an error message."""
        return None

    def _format_job_log(self, name, quant):
        return f'\n"-q {quant} -f {name}"\n'

    def _make_options(self, name, quant, outdir, max_rows, mono, bug, extra):
        """Builds and returns a ForwardOptions instance for a single job."""
        raise NotImplementedError

    # --- shared UI --------------------------------------------------------

    def _build_common_options(self):
        opts = ttk.Frame(self)
        opts.pack(fill="x", pady=(0, 8))
        ttk.Label(opts, text="Макс. строк на паттерн (-r):").grid(row=0, column=0, sticky="w")
        self.max_rows_entry = ttk.Entry(opts, width=8)
        self.max_rows_entry.insert(0, "256")
        self.max_rows_entry.grid(row=0, column=1, sticky="w", padx=(4, 20))
        self.mono_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(opts, text="Моно (-m)", variable=self.mono_var).grid(row=0, column=2, sticky="w")
        self.bug_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(opts, text="Эмуляция SB-бага 44кГц (-b)", variable=self.bug_var).grid(
            row=0, column=3, sticky="w", padx=(20, 0))

    def _build_table(self):
        table_frame = ttk.Frame(self)
        table_frame.pack(fill="both", expand=True)
        self._table_frame = table_frame
        # The table scrolls, so it only *asks* for a modest height (the default Canvas asks for
        # ~265 px, which made this tab - and with it the whole notebook - taller than the
        # "backward" tab and squeezed the log). It still expands to fill whatever room there is.
        canvas = tk.Canvas(table_frame, highlightthickness=0, height=170)
        vscroll = ttk.Scrollbar(table_frame, orient="vertical", command=canvas.yview)
        self.inner = ttk.Frame(canvas)
        self.inner.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=self.inner, anchor="nw")
        canvas.configure(yscrollcommand=vscroll.set)
        canvas.pack(side="left", fill="both", expand=True)
        vscroll.pack(side="right", fill="y")

        header = ttk.Frame(self.inner)
        header.grid(row=0, column=0, sticky="we", pady=(0, 4))
        ttk.Label(header, text="✓", width=3).grid(row=0, column=0)
        ttk.Label(header, text="Имя песни (-f)", width=20).grid(row=0, column=1)
        ttk.Label(header, text="Квантование (-q)", width=16).grid(row=0, column=2)

        for name, quant in DEFAULT_BATCH_SONGS:
            self._add_row(name, quant)

    def _build_buttons(self):
        btns = ttk.Frame(self)
        ttk.Button(btns, text="Добавить строку", command=lambda: self._add_row("", 4)).pack(side="left")
        ttk.Button(btns, text="Выделить все", command=lambda: self._set_all(True)).pack(side="left", padx=6)
        ttk.Button(btns, text="Снять всё", command=lambda: self._set_all(False)).pack(side="left")
        if self.show_list_songs_button:
            ttk.Button(btns, text="Список песен из WAD", command=self._list_songs).pack(side="left", padx=6)
        self.run_button = ttk.Button(btns, text=self.run_button_idle_text, command=self._run_batch)
        self.run_button.pack(side="right")

        progress_frame = ttk.Frame(self)
        # bottom-anchored and packed ahead of the table: if the tab is ever short of room it is the
        # table that shrinks (it scrolls), not the buttons
        progress_frame.pack(fill="x", pady=(6, 0), side="bottom", before=self._table_frame)
        btns.pack(fill="x", pady=(8, 0), side="bottom", before=self._table_frame)
        self.status_var = tk.StringVar(value="")
        ttk.Label(progress_frame, textvariable=self.status_var).pack(side="left")
        self.progress = ttk.Progressbar(progress_frame, orient="horizontal", mode="determinate")
        self.progress.pack(side="right", fill="x", expand=True, padx=(10, 0))

    def _poll_status(self):
        try:
            while True:
                kind, payload = self._status_queue.get_nowait()
                if kind == "start":
                    total = payload
                    self.progress.configure(maximum=max(total, 1), value=0)
                    self.run_button.configure(state="disabled", text=self.run_button_busy_text)
                    self._running = True
                elif kind == "progress":
                    done, total, name = payload
                    self.progress.configure(value=done)
                    self.status_var.set(f"Конвертирую {done}/{total}: {name}")
                elif kind == "done":
                    ok, fail = payload
                    self.progress.configure(value=self.progress["maximum"])
                    self.status_var.set(f"Готово: {ok} успешно, {fail} с ошибкой" if fail
                                         else f"Готово: {ok} песен сконвертировано")
                    self.run_button.configure(state="normal", text=self.run_button_idle_text)
                    self._running = False
                self.update_idletasks()
        except queue.Empty:
            pass
        self.after(50, self._poll_status)

    def _add_row(self, name, quant):
        r = len(self.rows) + 1
        row_frame = ttk.Frame(self.inner)
        row_frame.grid(row=r, column=0, sticky="we")
        enabled = tk.BooleanVar(value=True)
        ttk.Checkbutton(row_frame, variable=enabled).grid(row=0, column=0)
        name_var = tk.StringVar(value=name)
        ttk.Entry(row_frame, textvariable=name_var, width=20).grid(row=0, column=1, padx=2)
        quant_var = tk.StringVar(value=str(quant))
        ttk.Entry(row_frame, textvariable=quant_var, width=16).grid(row=0, column=2, padx=2)
        self.rows.append({"enabled": enabled, "name": name_var, "quant": quant_var})

    def _set_all(self, value):
        for row in self.rows:
            row["enabled"].set(value)

    def _collect_jobs(self):
        jobs = []
        for row in self.rows:
            if not row["enabled"].get():
                continue
            name = row["name"].get().strip()
            if not name:
                continue
            try:
                quant = int(row["quant"].get().strip())
            except ValueError:
                messagebox.showerror("Ошибка", f'Некорректное квантование для песни "{name}".')
                return None
            jobs.append((name, quant))
        return jobs

    def _run_batch(self):
        if self._running:
            messagebox.showinfo("Занято", "Конвертация уже выполняется.")
            return
        try:
            max_rows = int(self.max_rows_entry.get().strip())
        except ValueError:
            messagebox.showerror("Ошибка", "Некорректное значение максимума строк (-r).")
            return

        jobs = self._collect_jobs()
        if jobs is None:
            return
        if not jobs:
            messagebox.showinfo("Нечего делать", "Не выбрано ни одной песни.")
            return

        try:
            outdir = self._resolve_output_dir()
        except ValueError as e:
            messagebox.showerror("Ошибка", str(e))
            return

        mono = self.mono_var.get()
        bug = self.bug_var.get()

        def worker():
            self._status_queue.put(("start", len(jobs)))
            self.log_panel.log(f"Converting... ({len(jobs)} songs)\n")
            try:
                extra = self._prepare_jobs(jobs)
            except Exception as e:  # noqa: BLE001
                self.log_panel.log(f"Error: {e}\n")
                self._status_queue.put(("done", (0, len(jobs))))
                return

            ok, fail = 0, 0
            for i, (name, quant) in enumerate(jobs, start=1):
                self._status_queue.put(("progress", (i - 1, len(jobs), name)))
                try:
                    opts = self._make_options(name, quant, outdir, max_rows, mono, bug, extra)
                    self.log_panel.log(self._format_job_log(name, quant))
                    convert_forward(opts, log=self.log_panel.log)
                    ok += 1
                except ConversionError as e:
                    self.log_panel.log(f"Error: {e}\n")
                    fail += 1
                except Exception as e:  # noqa: BLE001
                    self.log_panel.log(f"Unexpected error converting \"{name}\": {e}\n")
                    fail += 1
                self._status_queue.put(("progress", (i, len(jobs), name)))
            self.log_panel.log(f"\nFinished. {ok} ok, {fail} failed.\n")
            self._status_queue.put(("done", (ok, fail)))

        threading.Thread(target=worker, daemon=True).start()


class WadBatchTab(_SongBatchTabBase):
    """Reproduces conv_wad.bat: converts songs straight out of doom2d.wad."""

    show_list_songs_button = True

    def _build_source_frame(self):
        top = ttk.Frame(self)
        top.pack(fill="x", pady=(0, 8))

        ttk.Label(top, text="Файл doom2d.wad:").grid(row=0, column=0, sticky="w")
        self.wad_entry = ttk.Entry(top, width=55)
        self.wad_entry.insert(0, "doom2d.wad")
        self.wad_entry.grid(row=0, column=1, sticky="we", padx=4)
        ttk.Button(top, text="Обзор...", command=lambda: browse_open(
            self.wad_entry, [("WAD files", "*.wad"), ("All files", "*.*")])).grid(row=0, column=2)

        ttk.Label(top, text="Папка для результатов (.xm):").grid(row=1, column=0, sticky="w", pady=(4, 0))
        self.outdir_entry = ttk.Entry(top, width=55)
        self.outdir_entry.grid(row=1, column=1, sticky="we", padx=4, pady=(4, 0))
        ttk.Button(top, text="Обзор...", command=lambda: browse_dir(self.outdir_entry)).grid(
            row=1, column=2, pady=(4, 0))
        top.grid_columnconfigure(1, weight=1)

    def _list_songs(self):
        wad_path = self.wad_entry.get().strip()
        if not os.path.isfile(wad_path):
            messagebox.showerror("Ошибка", f'Файл не найден: "{wad_path}"')
            return
        names = list_dmm_in_wad(wad_path)
        if names is None:
            messagebox.showerror("Ошибка", "Это не корректный WAD-файл.")
            return
        self.log_panel.log("Найдены DMM-песни в WAD:\n" + "\n".join(names) + "\n\n")

    def _resolve_output_dir(self):
        wad_path = self.wad_entry.get().strip()
        if not os.path.isfile(wad_path):
            raise ValueError(f'Файл не найден: "{wad_path}"')
        return self.outdir_entry.get().strip() or os.path.dirname(os.path.abspath(wad_path))

    def _prepare_jobs(self, jobs):
        # Parse the WAD file once and reuse it for every song, instead of
        # re-reading the whole file from disk for each one.
        wad_path = self.wad_entry.get().strip()
        wad = WadFile(wad_path)
        if not wad.valid:
            raise ConversionError(f'Invalid WAD file: "{wad_path}".')
        return wad

    def _make_options(self, name, quant, outdir, max_rows, mono, bug, extra):
        wad_path = self.wad_entry.get().strip()
        opts = ForwardOptions()
        opts.input_file = wad_path
        opts.dmm_in_wad_name = name
        opts.output_file = os.path.join(outdir, name + ".xm")
        opts.quantization = quant
        opts.max_rows = max_rows
        opts.no_stereo = mono
        opts.emulate_bug = bug
        opts.preloaded_wad = extra
        return opts


class DmmFolderBatchTab(_SongBatchTabBase):
    """Reproduces conv_dmm.bat: converts a folder of already-extracted .dmm
    files (e.g. pulled out of doom2d.wad with an external tool)."""

    show_list_songs_button = False

    def _build_source_frame(self):
        top = ttk.Frame(self)
        top.pack(fill="x", pady=(0, 8))

        ttk.Label(top, text="Папка с .dmm файлами:").grid(row=0, column=0, sticky="w")
        self.dmm_dir_entry = ttk.Entry(top, width=55)
        self.dmm_dir_entry.grid(row=0, column=1, sticky="we", padx=4)
        ttk.Button(top, text="Обзор...", command=lambda: browse_dir(self.dmm_dir_entry)).grid(
            row=0, column=2)

        ttk.Label(top, text="Папка для результатов (.xm):").grid(row=1, column=0, sticky="w", pady=(4, 0))
        self.outdir_entry = ttk.Entry(top, width=55)
        self.outdir_entry.grid(row=1, column=1, sticky="we", padx=4, pady=(4, 0))
        ttk.Button(top, text="Обзор...", command=lambda: browse_dir(self.outdir_entry)).grid(
            row=1, column=2, pady=(4, 0))
        top.grid_columnconfigure(1, weight=1)

        note = ("Ожидаются файлы вида \"ИмяПесни.dmm\" (как после распаковки .wad сторонним инструментом вроде QPak). Файлы инструментов (.DMI) должны\n"
                "лежать рядом, в той же папке, или в её подпапке \"dmi\\\".")
        ttk.Label(self, text=note, foreground="#888").pack(fill="x", pady=(0, 8), before=top)

    def _format_job_log(self, name, quant):
        return f'\n"-q {quant} {name}.dmm"\n'

    def _resolve_output_dir(self):
        dmm_dir = self.dmm_dir_entry.get().strip()
        if not dmm_dir or not os.path.isdir(dmm_dir):
            raise ValueError(f'Папка не найдена: "{dmm_dir}"')
        return self.outdir_entry.get().strip() or dmm_dir

    def _make_options(self, name, quant, outdir, max_rows, mono, bug, extra):
        dmm_dir = self.dmm_dir_entry.get().strip()
        opts = ForwardOptions()
        opts.input_file = os.path.join(dmm_dir, name + ".dmm")
        opts.output_file = os.path.join(outdir, name + ".xm")
        opts.quantization = quant
        opts.max_rows = max_rows
        opts.no_stereo = mono
        opts.emulate_bug = bug
        return opts


class SingleFileTab(ttk.Frame):
    def __init__(self, master, log_panel: LogPanel):
        super().__init__(master, padding=10)
        self.log_panel = log_panel

        r = 0
        ttk.Label(self, text="Входной файл (.dmm или .wad):").grid(row=r, column=0, sticky="w")
        self.input_entry = ttk.Entry(self, width=55)
        self.input_entry.grid(row=r, column=1, sticky="we", padx=4)
        ttk.Button(self, text="Обзор...", command=self._browse_input).grid(row=r, column=2)
        r += 1

        ttk.Label(self, text="Песня в WAD (-f), если входной файл - .wad:").grid(
            row=r, column=0, sticky="w", pady=(6, 0))
        self.song_entry = ttk.Entry(self, width=30)
        self.song_entry.grid(row=r, column=1, sticky="w", padx=4, pady=(6, 0))
        ttk.Button(self, text="Список песен из WAD", command=self._list_songs).grid(
            row=r, column=2, pady=(6, 0))
        r += 1

        ttk.Label(self, text="Квантование (-q):").grid(row=r, column=0, sticky="w", pady=(6, 0))
        self.quant_entry = ttk.Entry(self, width=10)
        self.quant_entry.insert(0, "4")
        self.quant_entry.grid(row=r, column=1, sticky="w", padx=4, pady=(6, 0))
        r += 1

        ttk.Label(self, text="Макс. строк на паттерн (-r):").grid(row=r, column=0, sticky="w", pady=(6, 0))
        self.rows_entry = ttk.Entry(self, width=10)
        self.rows_entry.insert(0, "256")
        self.rows_entry.grid(row=r, column=1, sticky="w", padx=4, pady=(6, 0))
        r += 1

        ttk.Label(self, text="Выходной файл (-o), необязательно:").grid(
            row=r, column=0, sticky="w", pady=(6, 0))
        self.output_entry = ttk.Entry(self, width=55)
        self.output_entry.grid(row=r, column=1, sticky="we", padx=4, pady=(6, 0))
        ttk.Button(self, text="Обзор...", command=lambda: browse_save(
            self.output_entry, [("XM module", "*.xm")], ".xm")).grid(row=r, column=2, pady=(6, 0))
        r += 1

        opts_frame = ttk.Frame(self)
        opts_frame.grid(row=r, column=0, columnspan=3, sticky="w", pady=(6, 0))
        self.mono_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(opts_frame, text="Моно (-m)", variable=self.mono_var).pack(side="left")
        self.bug_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(opts_frame, text="Эмуляция SB-бага 44кГц (-b)", variable=self.bug_var).pack(
            side="left", padx=(20, 0))
        r += 1

        self.run_button = ttk.Button(self, text="Конвертировать", command=self._run)
        self.run_button.grid(row=r, column=0, columnspan=3, pady=(12, 0))

        self.grid_columnconfigure(1, weight=1)

    def _browse_input(self):
        browse_open(self.input_entry, [("DMM/WAD files", "*.dmm *.wad"), ("All files", "*.*")])

    def _list_songs(self):
        wad_path = self.input_entry.get().strip()
        if not os.path.isfile(wad_path):
            messagebox.showerror("Ошибка", f'Файл не найден: "{wad_path}"')
            return
        names = list_dmm_in_wad(wad_path)
        if names is None:
            messagebox.showerror("Ошибка", "Это не корректный WAD-файл.")
            return
        self.log_panel.log("Найдены DMM-песни в WAD:\n" + "\n".join(names) + "\n\n")

    def _run(self):
        input_path = self.input_entry.get().strip()
        if not os.path.isfile(input_path):
            messagebox.showerror("Ошибка", f'Файл не найден: "{input_path}"')
            return
        try:
            quant = int(self.quant_entry.get().strip())
            max_rows = int(self.rows_entry.get().strip())
        except ValueError:
            messagebox.showerror("Ошибка", "Квантование и число строк должны быть целыми числами.")
            return

        opts = ForwardOptions()
        opts.input_file = input_path
        opts.dmm_in_wad_name = self.song_entry.get().strip()
        opts.output_file = self.output_entry.get().strip()
        opts.quantization = quant
        opts.max_rows = max_rows
        opts.no_stereo = self.mono_var.get()
        opts.emulate_bug = self.bug_var.get()

        def worker():
            try:
                convert_forward(opts, log=self.log_panel.log)
            except ConversionError as e:
                self.log_panel.log(f"Error: {e}\n")
            except Exception as e:  # noqa: BLE001
                self.log_panel.log(f"Unexpected error: {e}\n")

        self.run_button.configure(state="disabled", text="Идёт конвертация...")
        thread = threading.Thread(target=worker, daemon=True)
        thread.start()
        self._watch_thread(thread)

    def _watch_thread(self, thread):
        if thread.is_alive():
            self.after(100, lambda: self._watch_thread(thread))
        else:
            self.run_button.configure(state="normal", text="Конвертировать")


class BackwardTab(ttk.Frame):
    def __init__(self, master, log_panel: LogPanel):
        super().__init__(master, padding=10)
        self.log_panel = log_panel

        ttk.Label(self, text="Входной файл .xm, .s3m, .it или .mod:").grid(row=0, column=0, sticky="w")
        self.input_entry = ttk.Entry(self, width=55)
        self.input_entry.grid(row=0, column=1, sticky="we", padx=4)
        ttk.Button(self, text="Обзор...", command=lambda: browse_open(
            self.input_entry, [("Трекерные модули", "*.xm *.s3m *.it *.mod"), ("XM module", "*.xm"),
                                ("Scream Tracker 3", "*.s3m"), ("Impulse Tracker", "*.it"),
                                ("Amiga MOD", "*.mod"),
                                ("All files", "*.*")])).grid(row=0, column=2)

        ttk.Label(self, text="Выходной файл .dmm (-o), необязательно:").grid(
            row=1, column=0, sticky="w", pady=(6, 0))
        self.output_entry = ttk.Entry(self, width=55)
        self.output_entry.grid(row=1, column=1, sticky="we", padx=4, pady=(6, 0))
        ttk.Button(self, text="Обзор...", command=lambda: browse_save(
            self.output_entry, [("DMM file", "*.dmm")], ".dmm")).grid(row=1, column=2, pady=(6, 0))

        note = ("Файлы инструментов (.DMI) сохраняются в той же папке, что и результирующий .dmm.\n"
                "Форматы: XM (все версии), MOD, S3M (несжатые PCM-сэмплы), IT (включая сжатые IT214/IT215).\n"
                "MOD, упакованные ProPacker'ом (тег 'PPxx'), нужно распаковать заранее. Подробности - в README.")
        ttk.Label(self, text=note, foreground="#888").grid(
            row=2, column=0, columnspan=3, sticky="w", pady=(10, 0))

        self.channel_selection_var = tk.StringVar(value="loudness")
        ttk.Label(self, text="Для модулей с >8 каналами:").grid(
            row=3, column=0, columnspan=3, sticky="w", pady=(10, 0))
        ttk.Radiobutton(
            self, variable=self.channel_selection_var, value="first",
            text="Первые 8 по номеру (как было изначально)"
        ).grid(row=4, column=0, columnspan=3, sticky="w")
        ttk.Radiobutton(
            self, variable=self.channel_selection_var, value="count",
            text="8 самых используемых по количеству нот"
        ).grid(row=5, column=0, columnspan=3, sticky="w")
        ttk.Radiobutton(
            self, variable=self.channel_selection_var, value="loudness",
            text="8 самых используемых по суммарной громкости нот (рекомендуется)"
        ).grid(row=6, column=0, columnspan=3, sticky="w")
        ttk.Label(
            self, foreground="#888",
            text="Бас или соло (редкие, но громкие ноты) может проиграть по числу нот частым тихим украшениям."
        ).grid(row=7, column=0, columnspan=3, sticky="w", pady=(2, 0))

        ttk.Label(self, text="Изменение громкости во время ноты (слайды Axy/Dxy, огибающие IT):").grid(
            row=8, column=0, columnspan=3, sticky="w", pady=(10, 0))
        self._slide_modes = {
            "Как раньше: слайды игнорируются, огибающие IT запекаются в инструменты": "off",
            "События громкости - без новых инструментов (рекомендуется)": "events",
            "Запекать слайды и огибающие в инструменты (больше всего .DMI)": "bake",
        }
        self.volume_slides_var = tk.StringVar(
            value=next(label for label, mode in self._slide_modes.items() if mode == "events"))
        ttk.Combobox(self, textvariable=self.volume_slides_var, state="readonly",
                     values=list(self._slide_modes), width=72).grid(
            row=9, column=0, columnspan=3, sticky="w")
        ttk.Label(
            self, foreground="#888",
            text=("Событие 0xFF меняет громкость уже звучащей ноты: затухания и огибающие записываются без новых\n"
                  "инструментов (+4 байта на изменение, до 65535 нот). \"Запекание\" рисует их в семпле, но это новые ресурсы WAD.")
        ).grid(row=10, column=0, columnspan=3, sticky="w", pady=(2, 0))

        self.sample_offsets_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(
            self, variable=self.sample_offsets_var,
            text="Учитывать смещение семпла (Oxx/9xx): копии инструментов, до 32 на песню (лишние ресурсы WAD)"
        ).grid(row=11, column=0, columnspan=3, sticky="w", pady=(8, 0))

        self.split_subsongs_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(
            self, variable=self.split_subsongs_var,
            text="Разделить subsongs (Bxx/Cxx): каждая подпесня — свой .dmm с развёрнутым порядком, инструменты общие"
        ).grid(row=12, column=0, columnspan=3, sticky="w", pady=(2, 0))

        self.run_button = ttk.Button(self, text="Конвертировать в DMM", command=self._run)
        self.run_button.grid(row=13, column=0, columnspan=3, pady=(12, 0))

        self.grid_columnconfigure(1, weight=1)

    def _run(self):
        input_path = self.input_entry.get().strip()
        if not os.path.isfile(input_path):
            messagebox.showerror("Ошибка", f'Файл не найден: "{input_path}"')
            return
        output_path = self.output_entry.get().strip()
        channel_selection = self.channel_selection_var.get()
        volume_slides = self._slide_modes[self.volume_slides_var.get()]
        sample_offsets = self.sample_offsets_var.get()
        split_subsongs = self.split_subsongs_var.get()

        def worker():
            try:
                convert_backward(input_path, output_path, log=self.log_panel.log,
                                  channel_selection=channel_selection,
                                  volume_slides=volume_slides, sample_offsets=sample_offsets,
                                  split_subsongs=split_subsongs)
            except ConversionError as e:
                self.log_panel.log(f"Error: {e}\n")
            except Exception as e:  # noqa: BLE001
                self.log_panel.log(f"Unexpected error: {e}\n")

        self.run_button.configure(state="disabled", text="Идёт конвертация...")
        thread = threading.Thread(target=worker, daemon=True)
        thread.start()
        self._watch_thread(thread)

    def _watch_thread(self, thread):
        if thread.is_alive():
            self.after(100, lambda: self._watch_thread(thread))
        else:
            self.run_button.configure(state="normal", text="Конвертировать в DMM")


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("dmm2xm - Doom2D DMM <-> XM конвертер (Python GUI)")

        style = ttk.Style(self)
        try:
            style.theme_use("clam")
        except tk.TclError:
            pass

        notebook = ttk.Notebook(self)
        notebook.pack(fill="x", expand=False, padx=8, pady=(8, 4))

        log_frame = ttk.LabelFrame(self, text="Журнал")
        log_frame.pack(fill="both", expand=True, padx=8, pady=(4, 8))
        log_panel = LogPanel(log_frame)
        log_panel.pack(fill="both", expand=True, padx=4, pady=4)
        ttk.Button(log_frame, text="Очистить журнал", command=log_panel.clear).pack(
            anchor="e", padx=4, pady=(0, 4))

        batch_tab = WadBatchTab(notebook, log_panel)
        dmm_folder_tab = DmmFolderBatchTab(notebook, log_panel)
        single_tab = SingleFileTab(notebook, log_panel)
        backward_tab = BackwardTab(notebook, log_panel)

        notebook.add(batch_tab, text="Пакетная конвертация (WAD)")
        notebook.add(dmm_folder_tab, text="Пакетная конвертация (папка .dmm)")
        notebook.add(single_tab, text="Один файл (DMM/WAD → XM)")
        notebook.add(backward_tab, text="Обратно (XM → DMM)")

        # Start at the size the content actually asks for (tallest tab + a 12-line log + the clear
        # button) instead of a hard-coded height: no dead space, nothing clipped, whatever the
        # platform's fonts/DPI. Extra height from resizing goes to the log.
        self.update_idletasks()
        self.geometry(f"{max(880, self.winfo_reqwidth())}x{self.winfo_reqheight()}")


def main():
    app = App()
    app.mainloop()


if __name__ == "__main__":
    main()
