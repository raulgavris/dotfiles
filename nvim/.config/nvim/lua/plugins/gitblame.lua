return {
    "f-person/git-blame.nvim",
    config = function()
        require('gitblame').setup {
            -- Note how the `gitblame_` prefix is omitted in `setup`
            enabled = true,
            message_template = '| <author> • <date> • <summary> |',
            message_when_not_committed = 'Oh please, commit this !',
            delay = 1000,
            virtual_text_column = 100
        }
    end

}

