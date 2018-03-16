class SnippetNoteEntity < NoteEntity
  expose :toggle_award_path, if: -> (note, _) { note.emoji_awardable? } do |note|
    toggle_award_emoji_snippet_note_path(note.noteable, note)
  end

  expose :path do |note|
    snippet_note_path(note.noteable, note)
  end
end
