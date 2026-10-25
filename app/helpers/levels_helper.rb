# Colour classes for the four levels of exposure. Full class strings so
# Tailwind can see them.
module LevelsHelper
  CLASSES = {
    eist: { stripe: "bg-eist", text: "text-eist", tint: "bg-eist/10", border: "border-eist" },
    foghlaim: { stripe: "bg-foghlaim", text: "text-foghlaim", tint: "bg-foghlaim/10", border: "border-foghlaim" },
    cleacht: { stripe: "bg-cleacht", text: "text-cleacht", tint: "bg-cleacht/10", border: "border-cleacht" },
    labhair: { stripe: "bg-labhair", text: "text-labhair", tint: "bg-labhair/10", border: "border-labhair" }
  }.freeze

  def level_classes(level)
    CLASSES.fetch(level)
  end

  # Field recordings are listening material; everything else is the course.
  def lesson_level(lesson)
    lesson.lesson_type == "dias_material" ? :eist : :foghlaim
  end
end
