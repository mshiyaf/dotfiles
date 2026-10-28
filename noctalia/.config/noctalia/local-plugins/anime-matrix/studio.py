#!/usr/bin/env python3
"""Lid-centered, non-destructive AniMe Matrix editor."""

from __future__ import annotations

import json
import sys
import textwrap
import time
from pathlib import Path

import controller
from matrix_render import device_model, matrix_points, render
from PySide6.QtCore import QProcess, QRectF, QSize, Qt, QTimer, Signal
from PySide6.QtGui import QColor, QFont, QIcon, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (
    QApplication,
    QCheckBox,
    QComboBox,
    QDoubleSpinBox,
    QFileDialog,
    QFormLayout,
    QFrame,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QPushButton,
    QScrollArea,
    QSlider,
    QSplitter,
    QTabWidget,
    QVBoxLayout,
    QWidget,
)

ROOT = Path(__file__).parent
FONT_NAMES = {
    "mono": "DejaVu Mono · Bold",
    "sans": "DejaVu Sans · Bold",
    "serif": "DejaVu Serif · Bold",
    "orbitron": "Orbitron · Black",
    "space-mono": "Noto Sans Mono · Bold",
    "jetbrains": "JetBrains Mono · Bold",
    "jetbrains-light": "JetBrains Mono · Thin",
    "mono-italic": "DejaVu Mono · Oblique",
    "espacion": "ESPACION · Display",
}

STYLE = """
QWidget { color: #e8e9ed; font-family: 'DejaVu Sans'; font-size: 12px; }
QMainWindow, QTabWidget::pane { background: #101114; }
QFrame#panel { background: #191b20; border: 1px solid #2d3038; border-radius: 6px; }
QLabel#muted { color: #b1b6c2; }
QLabel#section { color: #a5aab6; font-size: 10px; font-weight: bold; }
QLabel#title { font-size: 25px; font-weight: bold; }
QPushButton { background: #252830; border: 1px solid #393d47; padding: 9px 14px; border-radius: 4px; }
QPushButton:hover { background: #343842; border-color: #707686; }
QPushButton:pressed, QPushButton:checked { background: #48212d; border-color: #ee4266; }
QPushButton:disabled { color: #656b78; }
QPushButton#apply { background: #d52c51; border-color: #ed4569; font-weight: bold; }
QLineEdit, QComboBox, QDoubleSpinBox { background: #101216; border: 1px solid #393d47; border-radius: 4px; min-height: 30px; padding: 2px 7px; }
QComboBox QAbstractItemView { background: #20232a; selection-background-color: #763047; }
QCheckBox { spacing: 9px; padding: 6px 0; }
QTabBar::tab { background: #191b20; color: #9ea4b2; padding: 12px 18px; border-bottom: 2px solid #292c34; }
QTabBar::tab:selected { color: #fff; border-bottom: 2px solid #ee4266; }
QListWidget { background: #111318; border: 1px solid #30343d; border-radius: 4px; padding: 5px; }
QListWidget::item { padding: 12px; border-radius: 3px; }
QListWidget::item:selected { background: #48212d; color: #fff; }
QScrollArea { border: none; background: transparent; }
QSlider::groove:horizontal { height: 3px; background: #404550; }
QSlider::handle:horizontal { width: 12px; margin: -5px 0; border-radius: 6px; background: #ee4266; }
QToolTip { background: #252830; color: #fff; border: 1px solid #555; }
"""


def label(text: str, name: str = "muted") -> QLabel:
    result = QLabel(text)
    result.setObjectName(name)
    result.setWordWrap(True)
    return result


class LidCanvas(QWidget):
    moved = Signal(float, float)

    def __init__(self, model: str):
        super().__init__()
        self.model = model
        self.points = matrix_points(model)
        self.frame = None
        self.zoom = 1.0
        self.start = None
        self.drag_width = 1
        self.drag_height = 1
        self.setMinimumSize(460, 330)
        self.setCursor(Qt.CursorShape.OpenHandCursor)
        self.setToolTip(
            "Drag to position content. The dots are the pixels sent to the lid."
        )
        self.setAccessibleName("Physical AniMe Matrix lid preview")

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        painter.fillRect(self.rect(), QColor("#0d0f12"))
        width = min(self.width() - 60, (self.height() - 80) * 1.57) * self.zoom
        height = width / 1.57
        lid = QRectF(
            (self.width() - width) / 2, (self.height() - height) / 2, width, height
        )
        painter.setPen(QPen(QColor("#454a55"), 1))
        painter.setBrush(QColor("#24272d"))
        painter.drawRoundedRect(lid, 12, 12)
        max_x = max(point[2] for point in self.points)
        max_y = max(point[3] for point in self.points)
        step = min((width - 38) / (max_x + 1), (height - 38) / (max_y + 1))
        self.drag_width = step * max_x
        self.drag_height = step * max_y
        origin_x = lid.right() - 20 - max_x * step
        origin_y = lid.top() + 18
        painter.setPen(Qt.PenStyle.NoPen)
        for x, y, px, py in self.points:
            strength = self.frame.getpixel((x, y)) if self.frame else 0
            painter.setBrush(
                QColor(strength, strength, strength)
                if strength > 20
                else QColor("#343941")
            )
            radius = max(0.7, step * 0.20)
            painter.drawEllipse(
                QRectF(
                    origin_x + px * step, origin_y + py * step, radius * 2, radius * 2
                )
            )
        painter.setPen(QColor("#8a909d"))
        painter.setFont(QFont("DejaVu Sans", 8))
        painter.drawText(
            QRectF(lid.left() + 20, lid.bottom() - 40, 180, 20), "REPUBLIC OF GAMERS"
        )
        painter.setPen(QColor("#585f6d"))
        painter.drawLine(
            int(lid.left() + width * 0.18),
            int(lid.bottom() - 9),
            int(lid.right() - width * 0.18),
            int(lid.bottom() - 9),
        )
        painter.end()

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self.start = event.position()
            self.setCursor(Qt.CursorShape.ClosedHandCursor)

    def mouseMoveEvent(self, event):
        if self.start is not None:
            delta = event.position() - self.start
            self.moved.emit(
                delta.x() / self.drag_width * 100, delta.y() / self.drag_height * 100
            )
            self.start = event.position()

    def mouseReleaseEvent(self, event):
        if self.start is not None:
            self.mouseMoveEvent(event)
            self.start = None
            self.setCursor(Qt.CursorShape.OpenHandCursor)


class Studio(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("AniMe Matrix Studio")
        self.setMinimumSize(1080, 780)
        self.resize(1440, 960)
        self.setStyleSheet(STYLE)
        self.model = device_model()
        self.loading = True
        self.scenes = []
        self.selected = -1
        self.playing = False
        self.started = time.monotonic()
        self.process = None
        self.build()
        self.load_state()
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.tick)
        self.timer.start(100)

    def button(self, text, callback, parent_layout, **kwargs):
        result = QPushButton(text)
        result.clicked.connect(callback)
        parent_layout.addWidget(result, **kwargs)
        return result

    def build(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setContentsMargins(24, 22, 24, 18)
        root.setSpacing(16)
        header = QHBoxLayout()
        titles = QVBoxLayout()
        eyebrow = label("ROG  /  PERSONAL LIGHTING", "section")
        eyebrow.setWordWrap(False)
        titles.addWidget(eyebrow)
        title = QLabel("AniMe Matrix Studio")
        title.setObjectName("title")
        titles.addWidget(title)
        header.addLayout(titles)
        header.addStretch()
        device_label = label(f"{self.model}  •  MONOCHROME MATRIX")
        device_label.setWordWrap(False)
        header.addWidget(device_label)
        self.apply_button = self.button("Apply Effect", self.apply, header)
        self.apply_button.setObjectName("apply")
        root.addLayout(header)
        splitter = QSplitter(Qt.Orientation.Horizontal)
        root.addWidget(splitter, 1)
        left = QFrame()
        left.setObjectName("panel")
        left_layout = QVBoxLayout(left)
        left_layout.setContentsMargins(16, 16, 16, 16)
        toolbar = QHBoxLayout()
        toolbar.addWidget(label("LID CANVAS", "section"))
        toolbar.addStretch()
        self.button("Reset transform", self.reset_transform, toolbar)
        toolbar.addWidget(label("Zoom"))
        zoom = QSlider(Qt.Orientation.Horizontal)
        zoom.setRange(70, 140)
        zoom.setValue(100)
        zoom.setFixedWidth(100)
        zoom.setAccessibleName("Canvas zoom")
        zoom.valueChanged.connect(self.zoom_canvas)
        toolbar.addWidget(zoom)
        left_layout.addLayout(toolbar)
        self.canvas = LidCanvas(self.model)
        self.canvas.moved.connect(self.move_content)
        left_layout.addWidget(self.canvas, 1)
        left_layout.addWidget(
            label(
                f"{len(self.canvas.points):,} addressable LEDs  /  shared preview + output raster  /  drag to position"
            )
        )
        sequence_header = QHBoxLayout()
        sequence_header.addWidget(label("SEQUENCE", "section"))
        sequence_header.addStretch()
        self.play_button = self.button("▶ Preview", self.toggle_play, sequence_header)
        left_layout.addLayout(sequence_header)
        self.timeline = QListWidget()
        self.timeline.setFlow(QListWidget.Flow.LeftToRight)
        self.timeline.setFixedHeight(88)
        self.timeline.currentRowChanged.connect(self.select_scene)
        left_layout.addWidget(self.timeline)
        actions = QHBoxLayout()
        self.button("+ Add clip", self.add_scene, actions)
        self.button("Duplicate", self.duplicate_scene, actions)
        self.button("←", lambda: self.reorder(-1), actions)
        self.button("→", lambda: self.reorder(1), actions)
        self.button("Remove", self.remove_scene, actions)
        actions.addStretch()
        self.position = label("Single effect · loops continuously")
        actions.addWidget(self.position)
        left_layout.addLayout(actions)
        splitter.addWidget(left)
        self.tabs = QTabWidget()
        self.tabs.setMinimumWidth(350)
        splitter.addWidget(self.tabs)
        splitter.setSizes([960, 390])
        design = QWidget()
        form = QFormLayout(design)
        form.setContentsMargins(18, 20, 18, 20)
        form.setVerticalSpacing(13)
        self.preset = QComboBox()
        for key, (title, _, _) in controller.PRESETS.items():
            self.preset.addItem(title, key)
        form.addRow("Content", self.preset)
        self.font = QComboBox()
        for key, title in FONT_NAMES.items():
            if Path(controller.FONTS[key]).is_file():
                self.font.addItem(title, key)
        form.addRow("Typeface", self.font)
        self.clock_style = QComboBox()
        for key, title in (
            ("digital", "Digital + date"),
            ("stacked", "Stacked hours / minutes"),
            ("rog", "ROG diagonal"),
        ):
            self.clock_style.addItem(title, key)
        form.addRow("Clock layout", self.clock_style)
        self.show_date = QCheckBox("Show date")
        form.addRow("", self.show_date)
        self.text = QLineEdit()
        self.text.setMaxLength(128)
        self.text.setPlaceholderText("Your message")
        form.addRow("Text", self.text)
        self.image = QLineEdit()
        self.image.setReadOnly(True)
        self.image.setPlaceholderText("PNG or animated GIF")
        form.addRow("Asset", self.image)
        browse = QPushButton("Import PNG / GIF…")
        browse.clicked.connect(self.choose_image)
        form.addRow("", browse)
        form.addRow(label("TRANSFORM", "section"))
        self.rotation = self.spin(-360, 360, 0.1, "°")
        self.scale = self.spin(10, 300, 1, "%")
        self.x = self.spin(-100, 100, 0.5, "")
        self.y = self.spin(-100, 100, 0.5, "")
        self.duration = self.spin(0.2, 30, 0.1, " s")
        for title, control in (
            ("Rotation", self.rotation),
            ("Scale", self.scale),
            ("Position X", self.x),
            ("Position Y", self.y),
            ("Clip duration", self.duration),
        ):
            form.addRow(title, control)
        form.addRow(
            label(
                "Rotation is clockwise on the lid. Position uses lid coordinates. Content outside the LED field is clipped."
            )
        )
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setWidget(design)
        self.tabs.addTab(scroll, "Design")
        self.build_library()
        self.build_device()
        footer = QHBoxLayout()
        self.status = label("Loading settings…")
        footer.addWidget(self.status, 1)
        self.button("Open design…", self.open_design, footer)
        self.button("Save design…", self.save_design, footer)
        self.button("Reload device", self.load_state, footer)
        root.addLayout(footer)
        for control in (self.preset, self.font, self.clock_style):
            control.currentIndexChanged.connect(self.changed)
        for control in (self.rotation, self.scale, self.x, self.y, self.duration):
            control.valueChanged.connect(self.changed)
        self.text.textChanged.connect(self.changed)
        self.show_date.toggled.connect(self.changed)

    def spin(self, low, high, step, suffix):
        control = QDoubleSpinBox()
        control.setRange(low, high)
        control.setSingleStep(step)
        control.setDecimals(1)
        control.setSuffix(suffix)
        return control

    def build_library(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(18, 20, 18, 20)
        layout.addWidget(label("CLOCK COLLECTION", "section"))
        for title, style, font, rotation in (
            ("Digital / precision", "digital", "jetbrains", 0),
            ("ROG / diagonal", "rog", "orbitron", 32),
            ("Stack / minimal", "stacked", "jetbrains-light", 0),
        ):
            self.button(
                title,
                lambda checked=False, s=style, f=font, r=rotation: self.clock_template(
                    s, f, r
                ),
                layout,
            )
        layout.addWidget(label("ROG GALLERY", "section"))
        gallery = QListWidget()
        gallery.setViewMode(QListWidget.ViewMode.IconMode)
        gallery.setResizeMode(QListWidget.ResizeMode.Adjust)
        gallery.setMovement(QListWidget.Movement.Static)
        gallery.setIconSize(QSize(100, 60))
        gallery.setGridSize(QSize(155, 120))
        gallery.setWordWrap(True)
        gallery.setTextElideMode(Qt.TextElideMode.ElideNone)
        for path in sorted(Path("/usr/share/asusd/anime/asus/rog").glob("*")):
            if path.suffix.lower() in {".png", ".gif"}:
                name = textwrap.fill(path.stem.replace("-", " ").replace("_", " "), 16)
                item = QListWidgetItem(
                    f"{'▶' if path.suffix.lower() == '.gif' else '◇'}  {name}"
                )
                item.setToolTip(path.stem)
                item.setIcon(QIcon(QPixmap(str(path))))
                item.setData(Qt.ItemDataRole.UserRole, str(path))
                gallery.addItem(item)
        gallery.itemClicked.connect(
            lambda item: self.use_image(item.data(Qt.ItemDataRole.UserRole))
        )
        layout.addWidget(gallery, 1)
        layout.addWidget(
            label(
                "Select an asset to edit it. Apply Effect is the only action that changes the lid."
            )
        )
        self.tabs.addTab(page, "Library")

    def build_device(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(18, 20, 18, 20)
        layout.addWidget(label("DISPLAY", "section"))
        self.enabled = QCheckBox("Enable AniMe Matrix")
        layout.addWidget(self.enabled)
        self.brightness = QComboBox()
        self.brightness.addItems(["off", "low", "med", "high"])
        layout.addWidget(label("Hardware brightness"))
        layout.addWidget(self.brightness)
        layout.addSpacing(20)
        layout.addWidget(label("POWER BEHAVIOR", "section"))
        self.off_unplugged = QCheckBox("Turn off on battery")
        self.off_suspended = QCheckBox("Turn off when suspended")
        self.off_lid_closed = QCheckBox("Turn off with lid closed")
        for control in (self.off_unplugged, self.off_suspended, self.off_lid_closed):
            layout.addWidget(control)
        layout.addWidget(
            label(
                "These switches control the LEDs only. Studio does not change the system lid/suspend policy or restart logind."
            )
        )
        layout.addStretch()
        self.tabs.addTab(page, "Device")

    def scene_values(self):
        return {
            "preset": self.preset.currentData(),
            "clock_font": self.font.currentData(),
            "custom_font": self.font.currentData(),
            "clock_rotation": self.rotation.value(),
            "custom_rotation": self.rotation.value(),
            "custom_text": self.text.text(),
            "custom_image": self.image.text(),
            "scale": self.scale.value() / 100,
            "x": self.x.value(),
            "y": self.y.value(),
            "duration": self.duration.value(),
            "show_date": self.show_date.isChecked(),
            "clock_style": self.clock_style.currentData(),
        }

    def values(self):
        return {
            **controller.DEFAULT,
            **self.scene_values(),
            "scenes": list(self.scenes),
            "enabled": self.enabled.isChecked(),
            "brightness": self.brightness.currentText(),
            "off_when_unplugged": self.off_unplugged.isChecked(),
            "off_when_suspended": self.off_suspended.isChecked(),
            "off_when_lid_closed": self.off_lid_closed.isChecked(),
        }

    def show_scene(self, scene):
        self.loading = True
        scene = {**controller.DEFAULT, **scene}
        for combo, value in (
            (self.preset, scene["preset"]),
            (
                self.font,
                scene["clock_font"]
                if scene["preset"] == "clock"
                else scene["custom_font"],
            ),
            (self.clock_style, scene["clock_style"]),
        ):
            combo.setCurrentIndex(max(0, combo.findData(value)))
        self.rotation.setValue(
            scene["clock_rotation"]
            if scene["preset"] == "clock"
            else scene["custom_rotation"]
        )
        self.scale.setValue(scene["scale"] * 100)
        self.x.setValue(scene["x"])
        self.y.setValue(scene["y"])
        self.duration.setValue(scene["duration"])
        self.text.setText(scene["custom_text"])
        self.image.setText(scene["custom_image"])
        self.show_date.setChecked(scene["show_date"])
        self.loading = False
        self.changed()

    def load_state(self):
        if self.process is not None:
            return
        try:
            self.load_values(controller.validate(controller.state()))
            self.status.setText("Ready. Edits stay in preview until you apply them.")
        except (OSError, ValueError, KeyError, TypeError) as error:
            self.status.setText(f"Could not load settings: {error}")

    def load_values(self, value):
        self.stop_playback()
        self.enabled.setChecked(value["enabled"])
        self.brightness.setCurrentText(value["brightness"])
        self.off_unplugged.setChecked(value["off_when_unplugged"])
        self.off_suspended.setChecked(value["off_when_suspended"])
        self.off_lid_closed.setChecked(value["off_when_lid_closed"])
        self.scenes = [dict(scene) for scene in value["scenes"]]
        self.selected = 0 if self.scenes else -1
        self.show_scene(self.scenes[0] if self.scenes else value)
        self.rebuild_timeline()

    def changed(self, *_):
        if self.loading:
            return
        self.stop_playback()
        if 0 <= self.selected < len(self.scenes):
            self.scenes[self.selected] = self.scene_values()
            self.rebuild_timeline()
        clock = self.preset.currentData() == "clock"
        text = self.preset.currentData() == "custom-text"
        self.clock_style.setEnabled(clock)
        self.show_date.setEnabled(clock)
        self.text.setEnabled(text)
        self.font.setEnabled(clock or text)
        self.started = time.monotonic()
        self.status.setText("Preview only. Choose Apply Effect to update the lid.")
        self.update_preview()

    def update_preview(self, scene=None, elapsed=0):
        try:
            value = {**controller.DEFAULT, **(scene or self.scene_values())}
            self.canvas.frame = render(value, self.model, elapsed)
            self.canvas.update()
        except (OSError, ValueError) as error:
            self.canvas.frame = None
            self.canvas.update()
            self.status.setText(f"Preview unavailable: {error}")

    def rebuild_timeline(self):
        self.timeline.blockSignals(True)
        self.timeline.clear()
        if not self.scenes:
            self.timeline.addItem("Single effect\nUse + Add clip to build a sequence")
        for index, scene in enumerate(self.scenes):
            title = controller.PRESETS[scene["preset"]][0]
            if scene["preset"] == "custom-image":
                title = Path(scene["custom_image"]).stem or "Image"
            self.timeline.addItem(
                f"{index + 1:02d}  {title}\n{scene.get('duration', 3):g} seconds"
            )
        self.timeline.setCurrentRow(self.selected)
        self.timeline.blockSignals(False)

    def select_scene(self, row):
        if 0 <= row < len(self.scenes):
            self.selected = row
            self.show_scene(self.scenes[row])

    def add_scene(self):
        if len(self.scenes) >= 12:
            self.status.setText("A sequence supports up to 12 clips.")
            return
        self.scenes.append(self.scene_values())
        self.selected = len(self.scenes) - 1
        self.stop_playback()
        self.rebuild_timeline()

    def duplicate_scene(self):
        self.add_scene()

    def remove_scene(self):
        if self.selected >= 0:
            self.scenes.pop(self.selected)
            self.selected = min(self.selected, len(self.scenes) - 1)
            self.stop_playback()
            if self.selected >= 0:
                self.show_scene(self.scenes[self.selected])
            self.rebuild_timeline()

    def reorder(self, direction):
        destination = self.selected + direction
        if self.selected >= 0 and 0 <= destination < len(self.scenes):
            self.scenes[self.selected], self.scenes[destination] = (
                self.scenes[destination],
                self.scenes[self.selected],
            )
            self.selected = destination
            self.rebuild_timeline()

    def stop_playback(self):
        self.playing = False
        self.play_button.setText("▶ Preview")
        self.position.setText(
            "Single effect · loops continuously"
            if not self.scenes
            else f"{len(self.scenes)} clips · {sum(s.get('duration', 3) for s in self.scenes):g} s loop"
        )

    def toggle_play(self):
        if self.playing:
            self.stop_playback()
            self.update_preview()
        else:
            self.playing = True
            self.started = time.monotonic()
            self.play_button.setText("Ⅱ Pause")

    def tick(self):
        elapsed = time.monotonic() - self.started
        if self.playing and self.scenes:
            elapsed %= sum(s["duration"] for s in self.scenes)
            for index, scene in enumerate(self.scenes):
                if elapsed < scene["duration"]:
                    self.position.setText(
                        f"Playing clip {index + 1} / {len(self.scenes)}"
                    )
                    self.update_preview(scene, elapsed)
                    break
                elapsed -= scene["duration"]
        else:
            self.update_preview(elapsed=elapsed if self.playing else 0)

    def zoom_canvas(self, value):
        self.canvas.zoom = value / 100
        self.canvas.update()

    def reset_transform(self):
        self.rotation.setValue(0)
        self.scale.setValue(100)
        self.x.setValue(0)
        self.y.setValue(0)

    def move_content(self, x, y):
        self.x.setValue(self.x.value() + x)
        self.y.setValue(self.y.value() + y)

    def clock_template(self, style, font, rotation):
        self.show_scene(
            {
                **self.scene_values(),
                "preset": "clock",
                "clock_style": style,
                "clock_font": font,
                "clock_rotation": rotation,
                "show_date": style != "rog",
                "scale": 1,
                "x": 0,
                "y": 7 if style == "rog" else 0,
            }
        )
        self.tabs.setCurrentIndex(0)

    def choose_image(self):
        path, _ = QFileDialog.getOpenFileName(
            self, "Import Matrix asset", "", "Matrix images (*.png *.gif)"
        )
        if path:
            self.use_image(path)

    def use_image(self, path):
        self.show_scene(
            {**self.scene_values(), "preset": "custom-image", "custom_image": path}
        )
        self.tabs.setCurrentIndex(0)

    def save_design(self):
        path, _ = QFileDialog.getSaveFileName(
            self, "Save Matrix design", "matrix-design.json", "Matrix design (*.json)"
        )
        if path:
            try:
                value = controller.validate(self.values())
                Path(path).write_text(json.dumps(value, indent=2) + "\n")
                self.status.setText(f"Saved {Path(path).name}. Device unchanged.")
            except (OSError, ValueError) as error:
                self.status.setText(str(error))

    def open_design(self):
        path, _ = QFileDialog.getOpenFileName(
            self, "Open Matrix design", "", "Matrix design (*.json)"
        )
        if path:
            try:
                saved = json.loads(Path(path).read_text())
                value = controller.validate({**controller.DEFAULT, **saved})
                self.load_values(value)
                self.status.setText(f"Opened {Path(path).name}. Preview only.")
            except (OSError, ValueError, TypeError, KeyError) as error:
                self.status.setText(f"Cannot open design: {error}")

    def apply(self):
        if self.process is not None:
            return
        try:
            value = controller.validate(self.values())
        except (ValueError, TypeError, KeyError) as error:
            self.status.setText(str(error))
            return
        self.process = QProcess(self)
        self.process.finished.connect(self.applied)
        self.process.errorOccurred.connect(self.apply_failed)
        self.apply_button.setEnabled(False)
        self.status.setText("Rendering and applying effect…")
        self.process.start(
            sys.executable,
            ["-B", str(ROOT / "controller.py"), "apply", json.dumps(value)],
        )

    def apply_failed(self, error):
        if self.process is not None and error == QProcess.ProcessError.FailedToStart:
            self.status.setText(self.process.errorString())
            self.process.deleteLater()
            self.process = None
            self.apply_button.setEnabled(True)

    def applied(self, *_):
        try:
            response = json.loads(bytes(self.process.readAllStandardOutput()).decode())
            self.status.setText(
                "Effect applied. Noctalia keeps live clocks updated."
                if response.get("ok")
                else response.get("error", "Apply failed")
            )
        except (ValueError, UnicodeError):
            self.status.setText(
                bytes(self.process.readAllStandardError()).decode(errors="replace")
                or "Controller did not respond."
            )
        self.process.deleteLater()
        self.process = None
        self.apply_button.setEnabled(True)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    app.setApplicationName("AniMe Matrix Studio")
    app.setDesktopFileName("anime-matrix-studio")
    window = Studio()
    window.show()
    sys.exit(app.exec())
