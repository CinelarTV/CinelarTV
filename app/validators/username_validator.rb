# frozen_string_literal: true

class UsernameValidator
  INVALID_CHAR_PATTERN = /[^\w.-]/
  INVALID_LEADING_CHAR_PATTERN = /\A[^\p{Alnum}_]+/
  INVALID_TRAILING_CHAR_PATTERN = /[^\p{Alnum}]+\z/
  REPEATED_SPECIAL_CHAR_PATTERN = /[-_.]{2,}/

  def self.perform_validation(object, field_name)
    validator = new(object.public_send(field_name))
    return if validator.valid?

    validator.errors.each { |e| object.errors.add(field_name.to_sym, e) }
  end

  def initialize(username)
    @username = username
    @errors = []
  end

  attr_reader :errors

  def valid?
    @errors.clear
    username_present?
    username_length_min?
    username_length_max?
    username_no_invalid_chars?
    username_first_char_valid?
    username_last_char_valid?
    username_no_double_special?
    username_no_at_symbol?
    @errors.empty?
  end

  private

  def username_present?
    @errors << I18n.t(:"user.username.blank") if @username.blank?
  end

  def username_length_min?
    return if @username.blank?

    @errors << I18n.t(:"user.username.short", count: 3) if @username.length < 3
  end

  def username_length_max?
    return if @username.blank?

    @errors << I18n.t(:"user.username.long", count: 20) if @username.length > 20
  end

  def username_no_invalid_chars?
    return if INVALID_CHAR_PATTERN.match?(@username).nil?

    @errors << I18n.t(:"user.username.characters") if INVALID_CHAR_PATTERN.match?(@username)
  end

  def username_first_char_valid?
    return if @username.blank?

    @errors << I18n.t(:"user.username.must_begin_with_alphanumeric_or_underscore") if INVALID_LEADING_CHAR_PATTERN.match?(@username)
  end

  def username_last_char_valid?
    return if @username.blank?

    @errors << I18n.t(:"user.username.must_end_with_alphanumeric") if INVALID_TRAILING_CHAR_PATTERN.match?(@username)
  end

  def username_no_double_special?
    return if @username.blank?

    @errors << I18n.t(:"user.username.must_not_contain_two_special_chars_in_seq") if REPEATED_SPECIAL_CHAR_PATTERN.match?(@username)
  end

  def username_no_at_symbol?
    @errors << I18n.t(:"user.username.must_not_contain_at_symbol") if @username&.include?("@")
  end
end
