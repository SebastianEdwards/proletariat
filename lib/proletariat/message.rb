# Internal: Struct to store message details for passing around.
#
# to      - The routing key for the message to as a String. In accordance
#           with the RabbitMQ convention you can use the '*' character to
#           replace one word and the '#' to replace many words.
# body    - The message as a String.
# headers - Hash of message headers.
class Message < Struct.new(:to, :body, :headers)
end
