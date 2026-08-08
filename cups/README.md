# CUPS Label Printer Package

GNU Stow package for the 75 x 50 mm thermal label printer setup (TSC-family
printers: TVS TT065-50, Zenpert 4T520).

Install / update:

```bash
make stow-cups        # or: make restow-cups to pick up new files
```

Not in `DEFAULT_PACKAGES` - this is machine-specific, so stow it explicitly.

## Contents

- `.local/bin/labelfix` - CUPS filter that renders any PDF to exactly 599 x 400
  dots (75 x 50 mm at 203 dpi) and emits native TSPL.
- `.local/share/cups-ppds/label-75x50mm.ppd` - Zebra ZPL PPD with a real
  `75 x 50 mm` page size and no A4/A5 entries.

## Why the filter exists

Browsers normalise paper to portrait and rotate the page content to match.
Chromium sends `Custom.138.90x212.60` (49 x 75 mm) even when the page CSS
correctly declares `@page { size: 7.5cm 5cm }` and the print dialog shows
`75 x 50 mm`. The printer then receives a 75 mm-long page for 50 mm labels,
feeds past where the gap should be, and faults with a red LED.

Nothing server-side fixes this: job options override queue defaults, and
`orientation-requested` is ignored once a job specifies an explicit custom page
size. So the filter re-renders every job at the true label geometry, rotating
portrait pages back to landscape.

Per job it: probes page orientation with `pdfinfo` (accounting for `/Rotate`),
rotates with `qpdf --rotate=-90` when portrait, renders at 599 x 400 with
`gs -sDEVICE=pbmraw -r203`, and wraps the bitmap in TSPL with `DENSITY 15` and
gap sensing.

Requires `qpdf`, `ghostscript`, `poppler` (`pdfinfo`), `python3`.

## Install

The PPD stows to `~/.local/share/cups-ppds/`, but CUPS filters must live in a
root-owned directory, so that part needs `sudo`:

```bash
make stow-cups
sudo install -m 755 ~/.local/bin/labelfix /usr/lib/cups/filter/labelfix
```

Then point a queue at the PPD:

```bash
lpadmin -p LABEL -E \
  -v 'usb://Bar%20Code%20Printer/TT065-50?serial=000001' \
  -P ~/.local/share/cups-ppds/label-75x50mm.ppd
lpadmin -p LABEL \
  -o Darkness=-1 \
  -o zeMediaTracking=Web \
  -o MediaType=Saved \
  -o Resolution=203dpi \
  -o printer-error-policy=retry-job
```

Find the device URI with `lpinfo -v`.

## Queue settings and why

| Option | Value | Reason |
| --- | --- | --- |
| `Darkness` | `-1` | Sends no ZPL darkness command, so the printer uses its stored TSPL `DENSITY`, whose ceiling is higher than ZPL's. |
| `MediaType` | `Saved` | Sends no ribbon-mode command. Forcing `SET RIBBON ON` triggers a false `0x08` ribbon fault on some units. |
| `zeMediaTracking` | `Web` | Gap-separated labels. |
| `printer-error-policy` | `retry-job` | Stops the queue disabling itself after a printer error and silently swallowing every later job. |

## Printer status over USB

The printer answers TSPL queries directly on its device node, which is far more
informative than CUPS job state:

```bash
exec 3<> /dev/usb/lp0 && printf '\x1b!?' >&3 && \
  timeout 2 dd bs=1 count=1 <&3 2>/dev/null | xxd -p; exec 3>&-
```

| Byte | Meaning |
| --- | --- |
| `00` | Normal |
| `01` | Head open |
| `02` | Paper jam |
| `04` | Out of paper |
| `08` | Out of ribbon |
| `10` | Paused |
| `20` | Printing |
| `80` | Other error |

Map device nodes to printers when more than one is attached - the numbering is
not stable across replugs:

```bash
for n in /sys/class/usbmisc/lp*; do
  echo "$n -> $(cat "$(dirname "$(realpath "$n/device")")/idProduct")"
done
```

`12a1` is the Zenpert 4T520, `0272` the TVS TT065-50.

## Gotchas

- **Do not install `tscdriver` (AUR).** Its `rastertobarcodetspl` filter
  segfaults on every job and emits zero bytes, so CUPS reports success while
  nothing prints. Its `brusb` backend claims the USB interface via usbfs and
  wedges the device until it is physically replugged. Use the stock `usb://`
  backend.
- **`media-ready` matters more than `media-default`.** Browsers trust the
  "currently loaded" media over the queue default. The stock Zebra PPD lists
  A4/A5 first, so CUPS advertised A4 as loaded and every browser requested it.
  Those entries are removed here.
- **Do not strip `ParamCustomPageSize`** from the PPD to block bad sizes. Jobs
  requesting `Custom.WxH` then fall back to US Letter instead of the default.
- **If jobs vanish, check `lpstat -p` first.** A queue that disables itself
  after an error keeps accepting jobs and prints none of them.
- **Faint output is usually consumables, not settings.** Print quality degrading
  across consecutive labels means the ribbon is not advancing; improving across
  them means a spent section is working through. Check take-up tension first.
