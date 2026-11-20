// ==========================================
// STUDENT NAME: Jennifer Njogu
// STUDENT ID: 01256232
// ==========================================

// ------------------------------------------------------------------------------
// Task 1: Clean Sheet / Defensive Shutout Sweep
// ------------------------------------------------------------------------------
db = db.getSiblingDB("sports_db_nosql");
db.live_game_logs.find(
  { sport_type: "soccer", match_status: "completed",
  "current_score.away":{$eq: 0}},
  { game_id: 1, home_team_name: 1, away_team_name: 1, current_score: 1, _id: 0}
)
.sort({ "current_score.home": -1 })
.limit(3);
// [DIAGNOSTIC REFLECTION 1]
// Answer:
// The home sort required -1 in order to get the  most
// home scores over 0 away scores in a complete game, the
// -1 integer represents the sorting of the games with the most
// home_scores over 0 away scores and positive 1 integer represents
// the sorting of the games with the least home_scores over 0 away scores.
// And the .limit(3) is the top dominant scores of home_scores over 0
// away scores.



// ------------------------------------------------------------------------------
// Task 2: Stoppage-Time Heroics
// ------------------------------------------------------------------------------
db = db.getSiblingDB("sports_db_nosql");
db.live_game_logs.find({
  sport_type: "soccer",
  timeline_events: {
    $elemMatch: {
      event_type: "goal",
      elapsed_minute: { $gte: 90 },
      actor_user_id: { $ne: "null"}
    }
}}, { game_id: 1,home_team_name: 1, away_team_name: 1, timeline_events: 1, _id: 0});



// [DIAGNOSTIC REFLECTION 2]
// Answer:
// Without the $elemMatch, each dotted-path
// evaluates independently across timeline_events, 
// meaning that event_type :goal would be in the list
// without the condition of elapsed_minutes being >= 90
// being filtered in the list and vise versa for
// for a timeline_event being >= 92 but not haivng
// event_type goal. $elemMatch makes it so that both
// coniditions are in timeline_event are filtered together in
// in the list Like an AND operator making sure that two conditions
// are true before going further with instructions.
// in PostgreSQL this query would be a joing between two relational
// databases sports_type and timeline_events with each elements having
// to match each criteria using the AND operator and the columns being the
// projection.


// ------------------------------------------------------------------------------
// Task 3: Cross-Sport Division Sweep
// ------------------------------------------------------------------------------
db = db.getSiblingDB("sports_db_nosql");
db.live_game_logs.find({
  "timeline_events.event_type": { $in: ["yellow_card", "foul"] }
}, { game_id: 1,sport_type: 1, home_team_name: 1, timeline_events: 1,_id: 0 });


// [DIAGNOSTIC REFLECTION 3]
// Answer:
// MongoDB stores each match as a document as a result doucments
// in the same collection don't have to share an identical structure.
// empty columns are not required in the document structure of MongoDB
// New feilds or ones with feilds that don't match are added to a document
// without any worry of how it disrupts the existing data in a document.



// ------------------------------------------------------------------------------
// Task 4: Architectural Reflection
// ------------------------------------------------------------------------------
// [DIAGNOSTIC REFLECTION 4]
// 1. In-Game Write Velocity:
// Answer:
// If the current score and timeline events are embedded in one match document,
// an update can change the score and append the event in a single document
// operation. This can avoid separate client round trips and the index, WAL, and
// row-update work associated with writing related records across normalized
// tables. It also avoids joins to reconstruct the match for live reads.
// MongoDB guarantees atomicity for that single-document update, so readers do
// not see only the score change or only the event append. This is not a
// guarantee of fewer physical disk writes in every workload: the document still
// has to be persisted, and a very active match document can become a contention
// point. PostgreSQL can also make multi-table updates atomic in a transaction,
// but coordinating the separate row writes and locks adds work.

// 2. Post-Game Reporting & Analysis:
// Answer:
// For season-wide standings, playoff tiebreakers, and payroll audits, the
// relational model is a better fit for joining teams, games, players, officials,
// and payments while enforcing their relationships and constraints. PostgreSQL
// provides expressive SQL joins and aggregations across normalized data,
// consistent types and foreign keys, and transactional updates that help keep
// financial records auditable. MongoDB can perform aggregations and joins too,
// but cross-document reporting over evolving or duplicated data often requires
// more pipeline logic and careful consistency controls. The relational model
// makes these historical, cross-game questions easier to express and validate.

// 3. Schema-on-Read Governance:
// Answer:
// Without a shared validation contract, clients may write the same event with
// incompatible field names, types, units, or meanings—for example, a minute as
// a number in one app and a string in another, or a missing actor represented
// as null, "null", or omitted. Those documents can all be stored, but later
// filters, aggregations, standings, and audits may silently miss or miscount
// events. Centralized server-side schema validation, consistent API contracts,
// and explicit schema-version handling are needed to prevent incompatible
// writes and make historical data reliable.

