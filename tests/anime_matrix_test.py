"""Observable rendering contracts for the lid editor, without hardware writes."""

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "noctalia/.config/noctalia/local-plugins/anime-matrix"
sys.path.insert(0, str(PLUGIN))
spec = importlib.util.spec_from_file_location("controller", PLUGIN / "controller.py")
controller = importlib.util.module_from_spec(spec)
spec.loader.exec_module(controller)


class MatrixRenderingTests(unittest.TestCase):
    def test_fine_rotation_and_transform_survive_validation(self):
        value = controller.validate(
            {
                **controller.DEFAULT,
                "clock_rotation": 32.7,
                "scale": 0.75,
                "x": -8.5,
                "y": 4.25,
            }
        )
        self.assertEqual(value["clock_rotation"], 32.7)
        for field, invalid in (
            ("scale", 0),
            ("x", float("nan")),
            ("clock_rotation", float("inf")),
        ):
            with self.subTest(field=field), self.assertRaises(ValueError):
                controller.validate({**value, field: invalid})

    def test_preview_pixels_are_the_exported_pixels(self):
        from matrix_render import export, matrix_points, pixel_size, render

        value = {
            **controller.DEFAULT,
            "preset": "custom-text",
            "custom_text": "L7",
            "custom_rotation": 23.4,
            "scale": 0.8,
            "x": 3,
            "y": -2,
        }
        frame = render(value, "GA402")
        self.assertEqual(frame.size, pixel_size("GA402"))
        points = matrix_points("GA402")
        self.assertEqual(len(points), 1449)
        self.assertEqual(len({(x, y) for x, y, _, _ in points}), 1449)
        mask = Image.new("L", frame.size)
        for x, y, _, _ in points:
            mask.putpixel((x, y), 255)
        from PIL import ImageChops

        self.assertIsNone(ImageChops.subtract(frame, mask).getbbox())
        self.assertIsNotNone(frame.getbbox())
        moved = render({**value, "x": -12}, "GA402")
        self.assertNotEqual(frame.tobytes(), moved.tobytes())
        self.assertEqual(points[0], (0, 33, 0, 0))
        self.assertEqual(points[-1][:2], (63, 30))
        with tempfile.TemporaryDirectory() as directory:
            mode, path = export(value, "GA402", Path(directory))
            self.assertEqual(mode, "pixel-image")
            with Image.open(path) as exported:
                self.assertEqual(exported.tobytes(), frame.tobytes())

    def test_sequence_validation_and_clock_refresh_contract(self):
        scene = {**controller.DEFAULT, "preset": "clock", "duration": 2.5}
        value = controller.validate({**controller.DEFAULT, "scenes": [scene]})
        self.assertEqual(value["scenes"][0]["duration"], 2.5)
        with self.assertRaises(ValueError):
            controller.validate({**value, "scenes": [{**scene, "duration": 0}]})

    def test_sequence_export_preserves_order_pixels_and_duration(self):
        from matrix_render import export, render

        first = {
            **controller.DEFAULT,
            "preset": "custom-text",
            "custom_text": "L7",
            "duration": 0.3,
        }
        second = {**first, "custom_text": "Z", "duration": 0.7}
        with tempfile.TemporaryDirectory() as directory:
            mode, path = export(
                {**first, "scenes": [first, second]}, "GA402", Path(directory)
            )
            self.assertEqual(mode, "pixel-gif")
            with Image.open(path) as gif:
                self.assertEqual(gif.n_frames, 2)
                self.assertEqual(
                    gif.convert("L").tobytes(), render(first, "GA402").tobytes()
                )
                self.assertEqual(gif.info["duration"], 300)
                gif.seek(1)
                # asusctl ignores GIF disposal. Every frame must overwrite the
                # whole raster, including LEDs that went dark since the last.
                self.assertEqual(gif.tile[0][1], (0, 0, 74, 39))
                self.assertEqual(
                    gif.convert("L").tobytes(), render(second, "GA402").tobytes()
                )
                self.assertEqual(gif.info["duration"], 700)

    def test_transparent_white_does_not_light_the_lid(self):
        from matrix_render import render

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "transparent.png"
            Image.new("RGBA", (50, 30), (255, 255, 255, 0)).save(path)
            value = {
                **controller.DEFAULT,
                "preset": "custom-image",
                "custom_image": str(path),
            }
            self.assertIsNone(render(value, "GA402").getbbox())


if __name__ == "__main__":
    unittest.main()
