module Mcp
  module Tools
    # Read-only: opens a designer's session. What became of the proposals since
    # a date (decisions, other people's comments, new evidence, new proposals)
    # and what is still waiting. Reads only; adds and changes nothing.
    class WhatChanged < Base
      DEFAULT_DAYS = 7
      LIMIT = 20
      WAITING_LIMIT = 5

      tool_name "what_changed"
      description "Start here when a course designer opens a session: what changed on course proposals " \
                  "and ideas since a date (default the last #{DEFAULT_DAYS} days). Lists proposals decided " \
                  "and by whom, new comments from other people, new evidence, new proposals, and what is " \
                  "still waiting (the open count and the ones waiting longest). Read-only."
      annotations(
        title: "What changed",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(
        properties: {
          since: { type: "string", description: "ISO 8601 date or time, e.g. 2026-11-15 (default: #{DEFAULT_DAYS} days ago)" }
        }
      )

      def self.call(server_context:, since: nil)
        from = parse_since(since)
        return error("Could not read since=#{since.inspect}; use a date like 2026-11-15") unless from
        return error("since must not be in the future") if from > Time.current
        me = server_context[:user]&.email_address.to_s.split("@").first.presence

        json_response(
          since: from.iso8601,
          decided: decided(from),
          new_comments: new_comments(from, me),
          new_evidence: new_evidence(from),
          new_proposals: new_proposals(from),
          waiting: waiting
        )
      end

      class << self
        private

        def parse_since(since)
          return DEFAULT_DAYS.days.ago if since.blank?
          text = since.to_s.strip
          # Strict ISO 8601 only, so a loose phrase is never read as a date.
          text.include?("T") ? Time.iso8601(text).in_time_zone : Date.iso8601(text).in_time_zone
        rescue ArgumentError, Date::Error
          nil
        end

        def decided(from)
          CourseProposal.where(decided_at: from..).order(decided_at: :desc).limit(LIMIT).map do |p|
            { id: p.id, title: p.title, status: p.status, decided_by: p.decided_by, decided_at: p.decided_at.iso8601 }
          end
        end

        # Comments by the person asking are left out: they already know what they said.
        def new_comments(from, me)
          scope = ProposalComment.includes(:course_proposal).where(created_at: from..)
          scope = scope.where.not(author: me) if me
          scope.order(created_at: :desc).limit(LIMIT).map do |c|
            { proposal_id: c.course_proposal_id, proposal_title: c.course_proposal.title,
              author: c.author, body: c.body, at: c.created_at.iso8601 }
          end
        end

        def new_evidence(from)
          ProposalEvidence.includes(:course_proposal).where(created_at: from..).order(created_at: :desc).limit(LIMIT).map do |e|
            { proposal_id: e.course_proposal_id, proposal_title: e.course_proposal.title,
              source: e.source, quote: e.quote, audio_url: e.audio_url, at: e.created_at.iso8601 }
          end
        end

        def new_proposals(from)
          CourseProposal.where(created_at: from..).order(created_at: :desc).limit(LIMIT).map do |p|
            { id: p.id, kind: p.kind, status: p.status, origin: p.origin, title: p.title, at: p.created_at.iso8601 }
          end
        end

        def waiting
          pending = CourseProposal.pending
          longest = pending.order(priority: :desc, created_at: :asc).limit(WAITING_LIMIT).map do |p|
            { id: p.id, kind: p.kind, status: p.status, title: p.title, waiting_since: p.created_at.iso8601 }
          end
          { open: pending.count, longest_waiting: longest }
        end
      end
    end
  end
end
