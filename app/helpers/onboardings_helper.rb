module OnboardingsHelper
  GAELTACHT_1926_URL = "https://abairt.com/1926".freeze

  REGIONS = [
    [ "erris", "Erris", "Belmullet, Carrowteige, Geesala" ],
    [ "achill", "Achill", "Achill Island and nearby" ],
    [ "tourmakeady", "Tourmakeady", "South Mayo, by Lough Mask" ],
    [ "east_mayo", "East Mayo", "Foxford, Ballindine and the Sligo border" ],
    [ "other", "Somewhere else", "Another part of Ireland or abroad, or not sure" ]
  ].freeze

  DOORS = [
    [ "beginner", "New to Irish", "I'm starting from scratch" ],
    [ "school_irish", "School Irish", "I had school Irish and lost confidence" ],
    [ "speaks_irish", "Speaks Irish already", "I speak Irish, but not Mayo Irish" ],
    [ "family", "Family", "I'm learning with children" ]
  ].freeze

  def region_name(user)
    REGIONS.find { |key, *| key == user.dialect_region }&.second
  end
end
