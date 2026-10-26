module OnboardingsHelper
  GAELTACHT_1926_URL = "https://abairt.com/1926".freeze

  # [value, name, description] triples for the onboarding form, translated.
  def region_choices
    User.dialect_regions.keys.map do |key|
      [ key, t("onboardings.regions.#{key}.name"), t("onboardings.regions.#{key}.note") ]
    end
  end

  def door_choices
    User.doors.keys.map do |key|
      [ key, t("onboardings.doors.#{key}.name"), t("onboardings.doors.#{key}.note") ]
    end
  end

  def region_name(user)
    t("onboardings.regions.#{user.dialect_region}.name") if user.dialect_region
  end
end
