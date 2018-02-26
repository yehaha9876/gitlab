import * as types from '../mutation_types';
import { findIndexOfFile, findEntry } from '../utils';

export default {
  [types.SET_FILE_ACTIVE](state, { file, active }) {
    Object.assign(file, {
      active,
    });

    Object.assign(state, {
      selectedFile: file,
    });
  },
  [types.TOGGLE_FILE_OPEN](state, file) {
    Object.assign(file, {
      opened: !file.opened,
    });

    if (file.opened) {
      state.openFiles.push(file);
    } else {
      state.openFiles.splice(findIndexOfFile(state.openFiles, file), 1);
    }
  },
  [types.SET_FILE_DATA](state, { data, file }) {
    Object.assign(file, {
      blamePath: data.blame_path,
      commitsPath: data.commits_path,
      permalink: data.permalink,
      rawPath: data.raw_path,
      binary: data.binary,
      html: data.html,
      renderError: data.render_error,
    });
  },
  [types.SET_FILE_RAW_DATA](state, { file, raw }) {
    Object.assign(file, {
      raw,
    });
  },
  [types.UPDATE_FILE_CONTENT](state, { file, content }) {
    const changed = content !== file.raw;

    Object.assign(file, {
      content,
      changed,
    });
  },
  [types.SET_FILE_LANGUAGE](state, { file, fileLanguage }) {
    Object.assign(file, {
      fileLanguage,
    });
  },
  [types.SET_FILE_EOL](state, { file, eol }) {
    Object.assign(file, {
      eol,
    });
  },
  [types.SET_FILE_POSITION](state, { file, editorRow, editorColumn }) {
    Object.assign(file, {
      editorRow,
      editorColumn,
    });
  },
  [types.DISCARD_FILE_CHANGES](state, file) {
    Object.assign(file, {
      content: file.raw,
      changed: false,
    });
  },
  [types.CREATE_TMP_FILE](state, { file, parent }) {
    parent.tree.push(file);
  },
  [types.ADD_FILE_TO_CHANGED](state, file) {
    const indexOfChangedFile = findIndexOfFile(state.changedFiles, file);

    if (indexOfChangedFile !== -1) {
      Object.assign(file, {
        staged: false,
      });
    } else {
      state.changedFiles.push(file);
    }
  },
  [types.REMOVE_FILE_FROM_CHANGED](state, file) {
    const indexOfChangedFile = findIndexOfFile(state.changedFiles, file);

    state.changedFiles.splice(indexOfChangedFile, 1);
  },
  [types.STAGE_CHANGE](state, file) {
    const stagedFile = findEntry(state.stagedFiles, 'blob', file.name);

    Object.assign(file, {
      staged: true,
    });

    if (stagedFile) {
      Object.assign(stagedFile, {
        ...file,
      });
    } else {
      state.stagedFiles.push({
        ...file,
      });
    }
  },
  [types.UNSTAGE_CHANGE](state, file) {
    const indexOfStagedFile = findIndexOfFile(state.stagedFiles, file);
    const changedFile = findEntry(state.changedFiles, 'blob', file.name);

    state.stagedFiles.splice(indexOfStagedFile, 1);

    Object.assign(changedFile, {
      staged: false,
    });
  },
};
