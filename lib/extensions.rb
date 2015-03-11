# Ignore if cache is not fresh anymore
module Faraday
  class HttpCache < Faraday::Middleware
    class Response
      def fresh?
        true
      end
    end
  end
end

class Time
  # remove timezone, to parse easier parse
  def to_s
    self.strftime "%Y-%m-%d %H:%M:%S"
  end
end
