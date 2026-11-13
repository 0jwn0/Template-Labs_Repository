// ==========================================
// STUDENT NAME: Jennifer Njogu
// STUDENT ID: 01256232
// ==========================================

// ------------------------------------------------------------------------------
// Ticket 0: Environment Verification
// ------------------------------------------------------------------------------
db = db.getSiblingDB("sports_db_nosql");
db.live_game_logs.countDocuments();



// ------------------------------------------------------------------------------
// Ticket 1: [AUDIT-9101] Live Scoreboard Audit
// ------------------------------------------------------------------------------
db = db.getSiblingDB("sports_db_nosql");
db.live_game_logs.find(
  { sport_type: "soccer", match_status: "completed",
  "current_score.home":{$gte: 3}},
  { game_id: 1, home_team_id: 1, away_team_id: 1, current_score: 1}
);


// [DIAGNOSTIC REFLECTION 1]
// Answer:
// The advantage of getting the current_score from the home as an
// embedded subdocument is that it allows for the score to appear
// in the document without needing a join between the home and other
// tables which is less amount of execution work to do. Mongo_db includes 
// the _id field in query results by default because the id is the primary information
// of any specific field and the syntax to exclude that field is ": 0".



// ------------------------------------------------------------------------------
// Ticket 2: [DISCIPLINE-9102] The Red Card Disciplinary Incident
// ------------------------------------------------------------------------------
db = db.getSiblingDB("sports_db_nosql");

// 1. Part A (Diagnostic Query):
db.live_game_logs.find({
  sport_type: "soccer",
  "timeline_events.event_type": "red_card",
  "timeline_events.elapsed_minute": { $gte: 45 }
}, { game_id: 1, _id: 0 });

// 2. Part B (Corrected Query):
db = db.getSiblingDB("sports_db_nosql");

db.live_game_logs.find({
  sport_type: "soccer",
  timeline_events: {
    $elemMatch: {
      event_type: "red_card",
      elapsed_minute: { $gte: 45 },
      period: "2H"
    }
}}, { game_id: 1,home_team_id: 1, away_team_id: 1, timeline_events: 1, _id: 0});


// [DIAGNOSTIC REFLECTION 2]
// Answer:
// The naive dot notation mistakenly matched game 4007
// because it did not include the restriction of the timeline_event
// time period which is 2H. MongoB's query engine require '$elemMatch' when
// filtering multiple properties of a object when that objects results must be
// isolated to those exact properties to show up in a document, not any properties
// that meet some of them.



// ------------------------------------------------------------------------------
// Ticket 3: [OPS-9103] In-Game Score Correction & Event Appending
// ------------------------------------------------------------------------------
db = db.getSiblingDB("sports_db_nosql");

// 1. Mutation:
db.live_game_logs.updateOne(
  { game_id: 4055 },
  {
    $set: { "current_score.away": 2 },
    $push: {
      timeline_events: {
        elapsed_minute: 88,
        period: "2H",
        event_type: "substitution",
        actor_user_id: 1042,
        details: "Late tactical substitution: J. Hanson for D. Miller"
      }
    }
  }
);

// 2. Verification Query:
db.live_game_logs.find(
  { sport_type: "soccer", game_id: 4055,},
  { game_id: 1, home_team_id: 1, away_team_id: 1, current_score: 1, timeline_events: 1, _id: 0}
);

// [DIAGNOSTIC REFLECTION 3]
// Answer:
// If a developer were to update without the $set
// operator the updatted feild would end up
// modifying other feilds in the document resulting in mass data loss.
// If an array feild inside a single MongoDB doucment grows without bounds read and updates
// become more costly and hit MongoBD's 16MB document size limit resulting in updates no longer
// being possible.

