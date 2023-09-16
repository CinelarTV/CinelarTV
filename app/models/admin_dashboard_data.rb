# frozen_string_literal: true

class AdminDashboardData
  def initialize(opts = {})
    @opts = opts
    @problems = []
  end

  def problems
    # Agrega los problemas verificados por símbolos a la lista de problemas
    problem_syms.each do |sym|
      send(sym)
    end

    # Agrega problemas adicionales basados en condiciones
    add_problem(
      content: "Your CinelarTV instance is not activated. Please enter a valid license key to continue using commercial features.",
      type: "critical",
      icon: "frown",
    ) unless CinelarTV.valid_license? && SiteSetting.enable_subscription

    add_problem(
      content: "Looks like you haven't completed the setup wizard yet. You can complete it by going to the <a href='/wizard'>setup wizard</a>.",
      type: "info",
      icon: "sparkles",
    ) unless SiteSetting.wizard_completed

    @problems.sort_by { |p| [p[:type] == "critical" ? 0 : 1, p[:type] == "info" ? 2 : 1] }
  end

  def problem_syms
    # Define aquí los problemas verificados por símbolos
    [:check_updates, :check_ram, :check_sidekiq]
  end

  def check_ram
    unless memory_info.total_memory.nil? || memory_info.total_memory > 1_000_000
      add_problem(
        content: I18n.t("dashboard.memory_warning"),
        icon: "cpu",
      )
    end
  end

  def check_updates
    add_problem(
      content: I18n.t("dashboard.updates_available"),
      icon: "rocket",
    ) if CinelarTV::Updater.updates_available? && SiteSetting.enable_web_updater
  end

  def check_sidekiq
    add_problem(
      content: I18n.t("dashboard.sidekiq_warning"),
      type: "critical",
      icon: "frown",
    ) if Sidekiq::ProcessSet.new.size.zero?
  end

  private

  def memory_info
    @memory_info ||= MemoryInfo.new
  end

  def add_problem(content:, type: "info", icon: "exclamation-triangle")
    @problems << {
      content: content,
      type: type,
      icon: icon,
    }
  end
end
