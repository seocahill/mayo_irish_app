module Mcp
  module Tools
    # Read-only: learners' spoken questions to native speakers, newest first,
    # with the speaker's answer and any ideas a designer saved from them.
    # Learners are never named, and their own recordings are not given out.
    class LearnerQuestions < Base
      DEFAULT_LIMIT = 10
      MAX_LIMIT = 25

      tool_name "learner_questions"
      description "The questions learners have recorded for a native speaker from Mayo, newest first: when each was asked, " \
                  "which lesson it was asked from (if any), whether it is waiting, with a speaker or answered, a link to the " \
                  "speaker's spoken answer once there is one, and the ideas a designer has already saved from it (open one with get_proposal). " \
                  "Learners are not named and their own recordings are not included; to hear a question, use the Learners' questions page. " \
                  "Status is as last checked with Abairt; opening the Learners' questions page checks for new answers. " \
                  "Optionally only one lesson's questions, or only those with no idea saved yet. Returns up to #{MAX_LIMIT} " \
                  "(default #{DEFAULT_LIMIT}), how many match and how many of those are answered, and the same two counts for the whole course. " \
                  "Changes nothing."
      annotations(
        title: "Learners' questions",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: {
        lesson: { type: "integer", description: "Only questions asked from this lesson number" },
        without_idea: { type: "boolean", description: "Only questions no idea has been saved from yet" },
        limit: { type: "integer", minimum: 1, maximum: MAX_LIMIT, description: "How many to return (1 to #{MAX_LIMIT}, default #{DEFAULT_LIMIT})" }
      })

      def self.call(server_context:, lesson: nil, without_idea: false, limit: nil)
        limit = (limit || DEFAULT_LIMIT).to_i.clamp(1, MAX_LIMIT)
        scope = NativeQuestion.all
        unless lesson.nil?
          found = Lesson.find_by(number: lesson)
          return error("There is no lesson #{lesson}.") unless found
          scope = scope.where(lesson: found)
        end
        scope = scope.where.not(id: ProposalEvidence.where.not(native_question_id: nil).select(:native_question_id)) if without_idea
        questions = scope.newest_first.includes(:lesson, proposal_evidence: :course_proposal).limit(limit)

        json_response(
          total: scope.count, answered: scope.answered.count,
          course_wide: { total: NativeQuestion.count, answered: NativeQuestion.answered.count },
          questions: questions.map { |q| describe(q) }
        )
      end

      def self.describe(question)
        {
          id: question.id, asked_at: question.created_at.iso8601, status: question.status,
          lesson: question.lesson && { number: question.lesson.number, title: question.lesson.title, published: question.lesson.published? },
          answered_at: question.answered_at&.iso8601,
          answer_audio_url: (question.answer_audio_url if question.answered? && question.answer_audio_url.to_s.start_with?("https://")),
          ideas: question.ideas.map { |p| { id: p.id, title: p.title, status: p.status } }
        }
      end
      private_class_method :describe
    end
  end
end
