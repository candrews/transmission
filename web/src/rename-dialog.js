/* @license This file Copyright (C) 2020-2022 Mnemosyne LLC.
   It may be used under GPLv2 (SPDX: GPL-2.0), GPLv3 (SPDX: GPL-3.0),
   or any future license endorsed by Mnemosyne LLC.
   License text can be found in the licenses/ folder. */

import { createDialogContainer } from './utils.js';

export class RenameDialog extends EventTarget {
  constructor(controller, remote) {
    super();

    this.controller = controller;
    this.remote = remote;
    this.elements = {};
    this.torrents = [];

    this.show();
  }

  show() {
    const torrents = this.controller.getSelectedTorrents();
    if (torrents.length !== 1) {
      console.trace();
      return;
    }

    this.torrents = torrents;
    this.elements = RenameDialog._create();
    this.elements.entry.value = torrents[0].getName();
    document.body.append(this.elements.root);

    this.elements.entry.focus();
  }

  close() {
    this.elements.root.remove();

    this.dispatchEvent(new Event('close'));

    delete this.controller;
    delete this.remote;
    delete this.elements;
    delete this.torrents;
  }

  _onDismiss() {
    this.close();
  }

  _onConfirm() {
    const [tor] = this.torrents;
    const old_name = tor.getName();
    const new_name = this.elements.entry.value;
    this.remote.renameTorrent([tor.getId()], old_name, new_name, (response) => {
      if (response.result === 'success') {
        tor.refresh(response.arguments);
      }
    });

    this.close();
  }

  static _create() {
    const elements = createDialogContainer('rename-dialog');
    elements.root.setAttribute('aria-label', 'Rename Torrent');
    elements.heading.textContent = 'Enter new name:';
    elements.confirm.textContent = 'Rename';
    elements.dismiss.addEventListener('click', () => this._onDismiss());
    elements.confirm.addEventListener('click', () => this._onConfirm());

    const label = document.createElement('label');
    label.setAttribute('for', 'torrent-rename-name');
    label.textContent = 'Enter new name:';
    elements.workarea.append(label);

    const entry = document.createElement('input');
    entry.setAttribute('type', 'text');
    entry.id = 'torrent-rename-name';
    elements.entry = entry;
    elements.workarea.append(entry);

    return elements;
  }
}
