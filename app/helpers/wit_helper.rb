module WitHelper
  require 'wit'
  def create_wit_app(app_name)
    client = initialize_wit
    client.create_new_app({ name: app_name, lang: 'en', private: true })
  end

  def train_wit_by_samples(text, understanding, token)
    p " in train_wit_by_samples given text = #{text}  and understanding = #{understanding} -----------------"
    client = initialize_wit(token)
    entity = []

    if understanding[:intent].present?
      begin
        client.post_intents({ name: understanding[:intent] })
      rescue Wit::Error => e
        p e
      end

    elsif understanding[:entity].present?
      begin
        client.post_entities({ name: understanding[:entity], roles: [] })
      rescue Wit::Error => e
        p e
      end

      entity_name = understanding[:entity].partition('wit$').last.presence || understanding[:entity]

      entity = [{ entity: "#{understanding[:entity]}:#{entity_name}",
                  start: 0,
                  end: text.length - 1,
                  body: text,
                  entities: [] }]
    end

    utterance = { text: text,
                  entities: entity,
                  traits: [] }

    utterance[:intent] = understanding[:intent] if understanding[:intent].present?

    p utterance
    client.post_utterances(utterance)
  end

  def query_wit(query, token)
    client = initialize_wit(token)
    puts "*** Querying Wit for #{query}"
    client.message(query)
  end

  private

  def initialize_wit(token = ENV['WIT_SERVER_TOKEN'])
    wit_client = Wit.new(access_token: token)
    wit_client.logger.level = Logger::DEBUG
    wit_client
  end
end
