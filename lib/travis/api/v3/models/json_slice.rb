require_relative './json_sync'

module Travis::API::V3
  class Models::JsonSlice
    include Virtus.model
    include Enumerable
    include Models::JsonSync
    include ActiveModel::Validations

    class << self
      attr_accessor :child_klass

      def child(klass)
        self.child_klass = klass
      end
    end

    def child_klass
      self.class.child_klass
    end

    def each(&block)
      return enum_for(:each) unless block_given?
      attributes.keys.each { |id| yield read(id) }
      self
    end

    def read(name)
      raise NotFound unless respond_to?(name)
      value = send(name)
      child_klass.new(name, value, parent) unless value.nil?
    end

    def update(name, value)
      raise NotFound unless respond_to?(:"#{name}=")
      send(:"#{name}=", value)
      raise UnprocessableEntity, errors.full_messages.to_sentence unless valid?
      sync!
      read(name)
    end

    def to_h
      Hash[map { |x| [x.name, x.value] }]
    end
  end
end
