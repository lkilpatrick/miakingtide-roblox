Here is the complete project plan in a single Markdown file. You can copy the code block below, save it as `MiaKingtide_GamePlan.md`, and use it to track your progress in Windsurf.

```markdown
# Project: Mia Kingtide - Find the Sea Creatures (Roblox)

**Context:** A Roblox exploration game based on the *Mia Kingtide* book series.
**Setting:** Monterey Bay, CA.
**Core Loop:** Explore → Locate Creature → Photograph (GoPro) → Unlock in Journal → Save.
**Tech Stack:** Roblox Lua, Rojo, ProfileService (optional).

---

## 🛠️ Prerequisite: System Context
*Copy and paste this into Windsurf at the start of the session to ground the AI in the project specifics.*

> **System Context:**
> We are building a Roblox game titled "Mia Kingtide: Find the Sea Creatures". The setting is Monterey Bay, CA.
>
> **The Creatures:**
> 1. **Marlow** (Sea Otter) - Found in Kelp Forest
> 2. **Luna** (Sea Lion) - Found on Rocky Outcrop
> 3. **Flip** (Harbor Seal) - Found near Pier Pylons
> 4. **Giant Pacific Octopus** - Found in Rocky Crevice (Cave)
> 5. **Bat Ray** - Found on Sandy Bottom
>
> **Tech Stack:**
> - Rojo file structure (src/server, src/client, src/shared)
> - Modular architecture (Service/Controller pattern)

---

## 🎫 Ticket 1: Project Scaffolding & Core Data
**Priority:** High
**Description:** Set up the Rojo file structure and the "Single Source of Truth" for creature data. Implement basic server-side data handling.

**Windsurf Prompt:**
```text
Create a comprehensive file structure for a Rojo-managed Roblox project. I need you to generate the following scripts:

1. src/shared/CreatureDefinitions.lua: A ModuleScript table defining our 5 creatures (Id, Name, Description, HabitatHint, UnlockFact).
2. src/server/PlayerDataHandler.server.lua: A server script handling PlayerAdded. It should load data (using a mock DataStore for now) to track which CreatureIds the player has unlocked.
3. src/shared/Events.folder: Define the RemoteEvents we will need (e.g., RequestCapture, UpdateJournal).

Ensure the code uses a modular structure where the creature data is the single source of truth.

```

---

## 🎫 Ticket 2: GoPro Tool Mechanics (Raycasting)

**Priority:** High
**Description:** Implement the "GoPro" tool that players use to capture creatures. This requires client-side visual feedback and server-side validation to prevent exploiting.

**Windsurf Prompt:**

```text
Create the logic for the "GoPro" tool. I need two files:

1. src/client/GoPro/Client.client.lua: A LocalScript. When equipped, it shows a UI crosshair. On click, it performs a client-side raycast. If it hits a part tagged "CreatureCollectible" within 40 studs, play a shutter sound and fire the RequestCapture RemoteEvent to the server.
2. src/server/CaptureValidation.server.lua: Listen for RequestCapture. Validate the distance (server-side check), ensure the target is a valid creature, and check if the player already unlocked it. If valid, update their data and fire a client event to show the "Unlocked" notification.

```

---

## 🎫 Ticket 3: Environment Placeholders (Command Bar Script)

**Priority:** Medium
**Description:** Create a script to procedurally generate the map layout in Roblox Studio. Since Windsurf cannot edit the 3D viewport directly, this script will be run manually in the Studio Command Bar.

**Windsurf Prompt:**

```text
Write a temporary script called MapSetup_CommandBar.lua.

This script should be designed to run in the Roblox Studio Command Bar. It should:
1. Create a Folder named "Habitats".
2. Instance 5 distinct Parts representing the habitats (Kelp Forest, Rocky Reef, Sandy Bottom, Pier, Tidepool) at different vector positions.
3. Color code them (e.g., Green for Kelp, Grey for Rock).
4. Place a dummy Model named after each creature (Marlow, Luna, etc.) inside their respective zones.
5. Apply the CollectionService tag "CreatureCollectible" to these dummy models.

This will allow me to visualize the map layout immediately.

```

---

## 🎫 Ticket 4: Field Journal UI Controller

**Priority:** Medium
**Description:** Build the client-side logic that manages the UI. It needs to interpret the data from the server and display the correct state (Locked vs. Unlocked) for each creature.

**Windsurf Prompt:**

```text
Create the client-side logic for the "Field Journal" UI in src/client/Controllers/JournalController.client.lua.

Features to implement:
1. Data Sync: Listen for the UpdateJournal remote to receive the player's current unlock list.
2. UI Construction: (Assume a ScreenGui named 'Journal' exists). Script the logic to loop through CreatureDefinitions.
3. State Logic:
   - If Locked: Show Silhouette + Name "???" + HabitatHint.
   - If Unlocked: Show Icon + Real Name + UnlockFact + Timestamp.
4. Notifications: Add a function showUnlockPopup(creatureId) that triggers when a new capture happens.

```

---

## 🎫 Ticket 5: Game Loop Completion & Debugging

**Priority:** Low (Polish)
**Description:** Implement the "Win State" when all 5 creatures are found and add developer tools for testing.

**Windsurf Prompt:**

```text
Update the PlayerDataHandler and JournalController to handle the "Completion State."

1. Check every time a capture happens if the user has 5/5 unlocks.
2. If 5/5, fire a specific remote to trigger a "Completion Celebration" on the client (confetti, "Monterey Bay Expert" badge UI).
3. Add a generic /reset chat command in the server script (restricted to my UserID) that wipes my data for testing purposes.

```