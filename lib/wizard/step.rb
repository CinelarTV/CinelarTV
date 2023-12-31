# frozen_string_literal: true

class Wizard
  class Step
    attr_reader :id, :updater
    attr_accessor :index, :fields, :next, :previous, :banner, :disabled, :description, :emoji

    def initialize(id)
      @id = id
      @fields = []
    end

    def add_field(attrs)
      field = Field.new(attrs)
      field.step = self
      @fields << field
      field
    end

    def fields?
      @fields.present?
    end

    def on_update(&block)
      # The updater is a block that receives a StepUpdater instance
      @updater = block
    end
  end
end
