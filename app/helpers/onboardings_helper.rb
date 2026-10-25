module OnboardingsHelper
  GAELTACHT_1926_URL = "https://abairt.com/1926".freeze

  REGIONS = [
    [ "erris", "Iorras", "Erris: Belmullet, Carrowteige, Geesala" ],
    [ "achill", "Acaill", "Achill" ],
    [ "tourmakeady", "Tuar Mhic Éadaigh", "Tourmakeady" ],
    [ "east_mayo", "Oirthear Mhaigh Eo", "East Mayo and the Sligo border: Foxford, Ballindine" ],
    [ "other", "Áit eile", "Somewhere else, or not sure" ]
  ].freeze

  DOORS = [
    [ "beginner", "Tosaitheoir", "I'm new to Irish" ],
    [ "school_irish", "Gaeilge scoile", "I had school Irish and lost confidence" ],
    [ "speaks_irish", "Labhraím cheana", "I speak Irish, but not Mayo Irish" ],
    [ "family", "Teaghlach", "I'm learning with children" ]
  ].freeze

  def region_name(user)
    ga, en = REGIONS.find { |key, *| key == user.dialect_region }&.drop(1)
    ga ? "#{ga} (#{en.split(':').first})" : nil
  end
end
