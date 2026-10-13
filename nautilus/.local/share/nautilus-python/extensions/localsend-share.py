"""Nautilus context menu entry that opens LocalSend with the selected files.

LocalSend preloads files and folders passed on its command line into the
send selection, so this only has to launch it with local paths.
"""

import shutil
import subprocess

from gi.repository import GObject, Nautilus


class LocalSendShareExtension(GObject.GObject, Nautilus.MenuProvider):
    def send_files(self, menu, paths):
        subprocess.Popen(
            ["localsend", *paths],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

    def get_file_items(self, *args):
        # Nautilus 4.0 passes [files]; 3.0 passed [window, files].
        files = args[-1]
        if not files or shutil.which("localsend") is None:
            return ()

        paths = [f.get_location().get_path() for f in files]
        # Only local files: LocalSend cannot read remote (sftp, smb...) URIs.
        if None in paths:
            return ()

        item = Nautilus.MenuItem(
            name="LocalSendShareExtension::Send",
            label="Send via LocalSend",
        )
        item.connect("activate", self.send_files, paths)
        return (item,)
