class ChangeDefaultTimestamps < ActiveRecord::Migration[6.1]
  def change
    change_column_default :dialogues, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :dialogues, :updated_at, from: nil, to: ->{ 'now()' }

    change_column_default :intents, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :intents, :updated_at, from: nil, to: ->{ 'now()' }

    change_column_default :variables, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :variables, :updated_at, from: nil, to: ->{ 'now()' }

    change_column_default :options, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :options, :updated_at, from: nil, to: ->{ 'now()' }

    change_column_default :responses, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :responses, :updated_at, from: nil, to: ->{ 'now()' }

    change_column_default :response_contents, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :response_contents, :updated_at, from: nil, to: ->{ 'now()' }

    change_column_default :arcs, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :arcs, :updated_at, from: nil, to: ->{ 'now()' }

    change_column_default :parameters, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :parameters, :updated_at, from: nil, to: ->{ 'now()' }

    change_column_default :conditions, :created_at, from: nil, to: ->{ 'now()' }
    change_column_default :conditions, :updated_at, from: nil, to: ->{ 'now()' }
  end
end
