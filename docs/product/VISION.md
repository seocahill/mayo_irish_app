# Vision — Mayo Irish App (working name)

Written and edited by the owner, not by the architect or builder. The architect
reads this first, every run, and treats it as the end state it is steering
toward. Change it whenever your thinking changes; it takes effect on the next
architect run (Sundays). Keep it short: a page is plenty.

For a quick steer between edits ("focus on X next week"), open an issue
labelled `owner-note` instead.

## What this is for

A platform for learning to understand and speak the Irish of Mayo and North
Connacht: Erris, Achill, Tourmakeady, Foxford and the Moy valley. (In the app
it is called Gaeilge Mhaigh Eo for now.)

It complements Abairt rather than competing with it. It uses Abairt's
recordings and transcriptions and adds other sources: the dialect monographs
(Mhac an Fhailigh's *The Irish of Erris*, de Búrca's *The Irish of
Tourmakeady*, *Notes on a Mayo Dialect*), the RIA's *Focail Fholaithe*,
irishlanguagemayo and others. The course is built on a proven skeleton, Ó
Siadhail's *Learning Irish*, rewritten in Mayo forms. Speech recognition,
speech synthesis and AI tutoring (ABAIR and LLMs) sit on top of it so that
learners hear and speak the language rather than only reading it.

## Who it serves

- **Learners**: adults who want to understand and speak Mayo Irish, to the
  level they choose. Many are from the diaspora or are coming back to the
  language. Most use phones, in short sessions, often on poor connections.
- **Course designers (admins)**: native speakers, volunteers and editors who
  design, edit and refine the course. They bring what no data can: a lifetime
  of the dialect. They get a very powerful design interface that does the
  drudge work, makes suggestions from all the data we hold, and leaves every
  decision to them.
- **Native speakers and contributors**: they answer learners' questions,
  record audio and correct content through whichever channel is easiest for
  them (Abairt, Telegram). They are credited, and they are told when their
  answer is used.
- **Other software**: Abairt, the agents that extract, plan and build the
  course, and researchers, all through a first-class API and MCP server.

## What great looks like

Let the best-in-class peers define "great" rather than spelling it out here.
The architect should name the peers it compares against in each proposal and
say where we fall short. In practice:

- **Learning** follows the evidence and the best language apps: active
  recall, spaced repetition, comprehensible input, speaking from day one.
- **Listening** puts native Mayo voices everywhere, with playback as good as
  mainstream audio and video apps, phone first.
- **Speaking practice** is honest about what the technology can judge in a
  minority dialect.
- **Course design** is better than the best authoring tools, because it knows
  the material. A designer can see where any word or rule is taught, heard
  and reviewed. The tool proposes from the data to hand: which items belong
  together, what to cross-reference, which recordings fit a lesson, what is
  duplicated, and what learners struggle with. It also points out gaps:
  everyday themes, situations and vocabulary that the course doesn't cover
  yet, so designers can fill them from their own knowledge of the dialect.
  Suggestions are always proposals that a designer accepts, edits or
  dismisses. The tool never writes Irish into the course itself.
- **Provenance** is on every item: which book and page it came from, or which
  speaker and place.
- **The API and MCP** are products in their own right: complete, documented
  and stable.
- **Language Specific** consider the unique feature of the irish language when designing. For instance the Irish genitive and plurals are less regular than english. It makes sense to learn these (and the gender) when learning a noun for example.

## Where it's going

Learning a language takes a long time and is often frustrating. Most learners
give up because they can't see that they are getting anywhere. The big moves,
in order:

1. **Measurable progress.** Track each learner's vocabulary, listening,
   speaking and grammar from what they actually do (reviews, listening time,
   minutes spoken, conversations). Show them honestly how far along they are
   in terms of real ability ("can follow a short story from Erris", "can hold
   a five-minute conversation"), not points.
2. **A daily path.** Each day the app knows what this learner should do next,
   sized to the time they have.
3. **All of Mayo Irish in the course.** The whole skeleton in Mayo forms, with
   the other sources woven in and native audio in every lesson.
4. **A loop with native speakers.** Learners' questions reach native speakers
   easily, and the answers flow back into the course and into Abairt.
5. **Our own speech and language models for Mayo Irish.** In the long run,
   speech recognition, speech synthesis and a tutor trained on Abairt and the
   course. Until then, ABAIR and general LLMs are good enough: keep them
   swappable and keep the corpus clean.

## What it should never become

- **A general learning platform**, or a course in another dialect or in the
  standard. There is one goal: more speakers of the Mayo dialects.
- **A source of invented Irish.** Irish comes from course material, Abairt,
  native speakers or transcripts. The one exception is the lesson
  conversation (comhrá): it is labelled as AI, can be flagged, and is never
  saved as course material.
- **"Corrected"** into the standard or Connemara forms. Dialect forms stay as
  the sources and speakers give them.
- **Manipulative.** No guilt mechanics, fake urgency or streak anxiety.
- **A substitute for people.** It should point learners towards native
  speakers and real conversation, not away from them.
- **Careless with data.** Collect only what helps learning. Speakers'
  recordings are theirs and Abairt's.

## Current priorities

- **A best-in-class learning interface.** A clear course structure, a daily
  "what's next", and progress that the learner can see and trust.
- **A powerful course design interface.** Anything that helps our teachers
  design the course well: data-driven suggestions (grouping, cross-references,
  matching recordings, duplicates), pointers to missing themes and gaps, and
  turning the Connemara skeleton into Mayo Irish.
- **Build in small steps.** Both of the above are large. The architect breaks
  them into a sequence of small issues that each ship on their own, not one
  big build.
