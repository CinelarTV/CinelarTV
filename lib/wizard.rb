# frozen_string_literal: true

# lib/wizard.rb
require "wizard/step"
require "wizard/field"
require "wizard/builder"
require "wizard/step_updater"

class Wizard
  attr_reader :steps, :user

  def initialize(user)
    @steps = []
    @user = user
  end

  def create_step(step_name)
    Step.new(step_name)
  end

  def append_step(step, after: nil)
    step = create_step(step) if step.is_a?(String)
    yield step if block_given?

    if after
      before_step = @steps.detect { |s| s.id == after }

      if before_step
        step.previous = before_step
        step.index = before_step.index + 1
        if before_step.next
          step.next = before_step.next
          before_step.next.previous = step
        end
        before_step.next = step
        @steps.insert(before_step.index + 1, step)
        step.index += 1 while (step = step.next)
        return
      end
    end

    last_step = @steps.last
    @steps << step

    # If it's the first step
    if @steps.size == 1
      @first_step = step
      step.index = 0
    elsif last_step.present?
      last_step.next = step
      step.previous = last_step
      step.index = last_step.index + 1
    end
  end

  def create_updater(step_id, fields)
    step = @steps.detect { |s| s.id == step_id }
    Wizard::StepUpdater.new(@user, step, fields)
  end

  def start
    # Devolver el último paso completado, o el primer paso si no hay ninguno
    last_completed_step = @steps.reverse.detect { |step| completed_steps?(step) }
    last_completed_step || @first_step
  end

  def completed_steps?(steps)
    steps = [steps].flatten.uniq

    steps.all? do |step|
      step = @steps.detect { |s| s.id == step } if step.is_a?(String)
      step.present? && step.fields.all? { |f| f.value.present? }
    end
  end

  def completed?
    completed_steps?(@steps)
  end

  def require_completion?
    false unless SiteSetting.wizard_enabled
    # Define otros métodos y funcionalidades necesarias aquí
  end
end
