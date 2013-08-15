require 'ploy/cli/config'
require 'ploy/cli/errors'

module Ploy
  module CLI
    module Helpers
      protected
      
      def client
        @client ||= (
          host = CLI.config.ploy_host
          token = CLI.config.ploy_token
          raise ConfigurationError, "Unknown host" unless host
          raise ConfigurationError, "Unknown token" unless token

          require 'ploy/client'
          Client.new(host: host, token: token)
        )
      end

      def display_table(objects, columns, headers)
        lengths = []
        columns.each_with_index do |column, index|
          header = headers[index]
          items = [header].concat(objects.map { |o| o[column].to_s })
          lengths << items.map { |i| i.to_s.length }.sort.last
        end
        lines = lengths.map {|length| "-" * length}
        lengths[-1] = 0 # remove padding from last column
        display_row headers, lengths
        display_row lines, lengths
        objects.each do |row|
          display_row columns.map { |column| row[column] }, lengths
        end
      end

      def display_row(row, lengths)
        row_data = []
        row.zip(lengths).each do |column, length|
          format = column.is_a?(Fixnum) ? "%#{length}s" : "%-#{length}s"
          row_data << format % column
        end
        display(row_data.join("  "))
      end

      def display(msg="", new_line=true)
        if new_line
          puts(msg)
        else
          print(msg)
          $stdout.flush
        end
      end

    end
  end
end
