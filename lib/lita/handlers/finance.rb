module Lita
  module Handlers
    class Finance < Handler
      route %r{(finance search) (.+)}i, :search, command: true, help: { 'finance search NAME' => 'Replies with a list of matching ticker SYMBOLS.' }
      route %r{(finance info) (.+)}i,   :info,   command: true, help: { 'finance info SYMBOL' => 'Replies with latest financial information for SYMBOL' }

      def search(response)
        search = response.matches[0][1]

        http_response = http.get(
          'http://autoc.finance.yahoo.com/autoc',
          query: search,
          region: 'EU',
          lang: 'en-US'
        )

        data = MultiJson.load(http_response.body)

        results = data['ResultSet']['Result']

        reply = ''
        results.each_with_index do |result, index|
          reply << "#{index + 1}. #{result['name']}: #{result['symbol']} - #{result['exchDisp']} - #{result['typeDisp']}\n"
        end

        response.reply !reply.empty? ? reply : 'No results found.'

      rescue
        response.reply 'Something went wrong. Try again.'
      end

      def info(response)
        symbol = response.matches[0][1]

        http_response = http.get(
          'https://query.yahooapis.com/v1/public/yql',
          q: "select * from yahoo.finance.quote where symbol in ('#{symbol}')",
          format: 'json',
          env: 'store://RjdEzitN2Hceujh3tGHPj6'
        )

        data = MultiJson.load(http_response.body)

        quote = data['query']['results']['quote']

        quote.delete('symbol')

        reply = ''
        quote.each do |key, value|
          value = value.nil? ? 'N/A' : value
          reply << "#{key}: #{value}\n"
        end

        response.reply reply

      rescue
        response.reply 'Something went wrong. Try again.'
      end

      Lita.register_handler(self)
    end
  end
end
