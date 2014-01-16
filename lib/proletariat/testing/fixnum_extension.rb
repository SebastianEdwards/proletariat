# Public: Extends Fixnum to provide sugar for creating Expectation instances.
class Fixnum
  # Public: Builds an Expectation instance which listens for a quantity of
  #         messages equal to self on any topic.
  #
  # Returns a new Expectation instance.
  def messages
    Proletariat::Testing::Expectation.new(['#'], self)
  end
end
