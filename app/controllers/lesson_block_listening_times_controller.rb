# A lesson's audio player reporting, every half minute or so and when the
# learner pauses or leaves, how long it has been playing. Counts towards
# minutes listened, like listening clips and whole recordings do.
class LessonBlockListeningTimesController < ApplicationController
  # The page reports a few times a minute at most; this only stops a runaway script.
  rate_limit to: 30, within: 1.minute, by: -> { current_user.id }, with: -> { head :too_many_requests }

  def update
    LessonBlock.where(block_type: "audio", lesson: Lesson.visible_to(current_user)).joins(:file_attachment).find(params[:lesson_block_id])
    ListeningDay.add_clip(current_user, params[:seconds].to_s)
    head :no_content
  end
end
