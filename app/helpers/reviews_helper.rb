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

  # The eyebrow over a noun-form card.
  def noun_form_label(question)
    question.direction == "plural" ? t("reviews.show.noun_form.plural") : t("reviews.show.noun_form.genitive")
  end
end
