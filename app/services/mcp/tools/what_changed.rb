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
                  "still waiting (the open count and the ones waiting longest). Each list shows up to " \
                  "#{LIMIT}; totals gives the full counts. Read-only."
      annotations(
        title: "What changed",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(
        properties: {
          since: { type: "string", description: "ISO 8601 date or time, e.g. 2026-11-15 or 2026-11-15T09:00; Irish time unless a zone is given (default: #{DEFAULT_DAYS} days ago)" }
        }
      )

      def self.call(server_context:, since: nil)
        from = parse_since(since)
        return error("Could not read since=#{since.inspect}; use a date like 2026-11-15") unless from
        return error("since must not be in the future") if from > Time.current
        me = server_context[:user]&.email_address.to_s.split("@").first.presence

        decided_rows = decided_scope(from)
        comment_rows = comments_scope(from, me)
        evidence_rows = evidence_scope(from)
        proposal_rows = proposals_scope(from)

        json_response(
          since: from.iso8601,
          # Totals, so a chat can tell when a list below stops at #{LIMIT}.
          totals: { decided: decided_rows.count, new_comments: comment_rows.count,
                    new_evidence: evidence_rows.count, new_proposals: proposal_rows.count },
          decided: decided(decided_rows),
          new_comments: new_comments(comment_rows),
          new_evidence: new_evidence(evidence_rows),
          new_proposals: new_proposals(proposal_rows),
          waiting: waiting
        )
      end

      class << self
        private

        def parse_since(since)
          return DEFAULT_DAYS.days.ago if since.blank?
          # Strict ISO 8601 only, so a loose phrase is never read as a date. A
          # date or a time without a zone is read in the app's zone (Dublin).
          Time.zone.iso8601(since.to_s.strip)
        rescue ArgumentError
          nil
        end

        def decided_scope(from) = CourseProposal.where(decided_at: from..)

        # Comments by the person asking are left out: they already know what they said.
        def comments_scope(from, me)
          scope = ProposalComment.where(created_at: from..)
          me ? scope.where.not(author: me) : scope
        end

        def evidence_scope(from) = ProposalEvidence.where(created_at: from..)
        def proposals_scope(from) = CourseProposal.where(created_at: from..)

        def decided(scope)
          scope.order(decided_at: :desc).limit(LIMIT).map do |p|
            { id: p.id, title: p.title, status: p.status, decided_by: p.decided_by, decided_at: p.decided_at.iso8601 }
          end
        end

        def new_comments(scope)
          scope.includes(:course_proposal).order(created_at: :desc).limit(LIMIT).map do |c|
            { proposal_id: c.course_proposal_id, proposal_title: c.course_proposal.title,
              author: c.author, body: c.body, at: c.created_at.iso8601 }
          end
        end

        def new_evidence(scope)
          scope.includes(:course_proposal).order(created_at: :desc).limit(LIMIT).map do |e|
            { proposal_id: e.course_proposal_id, proposal_title: e.course_proposal.title,
              source: e.source, quote: e.quote, audio_url: e.audio_url, at: e.created_at.iso8601 }
          end
        end

        def new_proposals(scope)
          scope.order(created_at: :desc).limit(LIMIT).map do |p|
            { id: p.id, kind: p.kind, status: p.status, origin: p.origin, title: p.title, at: p.created_at.iso8601 }
          end
        end

        def waiting
          pending = CourseProposal.pending
          longest = pending.order(created_at: :asc, id: :asc).limit(WAITING_LIMIT).map do |p|
            { id: p.id, kind: p.kind, status: p.status, title: p.title, waiting_since: p.created_at.iso8601 }
          end
          { open: pending.count, longest_waiting: longest }
        end
      end
    end
  end
end
