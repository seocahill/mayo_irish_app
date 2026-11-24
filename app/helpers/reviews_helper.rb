module ReviewsHelper
  # "The plural of bád?" for a noun-form review card, with the word marked as Irish.
  def noun_form_prompt(question)
    word = tag.span(question.prompt, lang: "ga", class: "italic")
    if question.direction == "plural"
      t("reviews.show.noun_form.prompt_plural_html", word: word)
    else
      t("reviews.show.noun_form.prompt_genitive_html", word: word)
    end
  end

  # "Masculine" or "Feminine" for the course's "m" or "f" (blank for anything else).
  def gender_name(gender)
    case gender
    when "m" then t("reviews.noun_forms.masculine")
    when "f" then t("reviews.noun_forms.feminine")
    else ""
    end
  end

  # The eyebrow over a noun-form card.
  def noun_form_label(question)
    question.direction == "plural" ? t("reviews.show.noun_form.plural") : t("reviews.show.noun_form.genitive")
  end
end
