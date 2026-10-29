# Workflow

This is a multi-agent, top-down workflow; the idea is that a large and capable model (the "coordinator") is given a problem statement from
the human user, builds a plan, builds a spec, breaks up the work into appropriately sized tasks and coordinates allocating the work to a
number of "coder", "deployer" and "tester" agents (which are all smaller, less-capable models).

The "pi-team-room" extension is the mechanism by which agents can communicate; communications should primarily only flow between the
"coordinator" and the "coder", "deployer" or "tester" agents (i.e. top-down) and not laterally (for ease of the "coordinator").

# Guiding principles

- Thin, vertical, full-depth slices
- Build reusable tooling
- Aim to validate the skeleton in the local environment early
- Aim to validate the skeleton in the target environment soon after
- Try to keep the local environment in sync with master unless it isn't feasible
  - This may mean rebuilding / restarting / redeploying the local environment as each branch is merged into master
- Try to keep the target environment in sync with master as features are completed / milestones are achieved

# The "coordinator" agent only

- The user will provide a rough goal / requirements
- Ask for clarification early if required
- Carefully maintain `docs/PLAN.md`, `docs/SPEC.md`, `docs/tasks/*.md` and `docs/STATUS.md`
- The plan leads into the spec and together they are decomposed into suitably sized (for a Qwen 3.5 9b model at Q5_K_M) tasks, named with a numbering
  system that is friendly to filesystems and branch names; the status of tasks are updated as they change
- Allocate tasks among the applicable agents; dev work to coders, local or target environment work to deployers, local or target environment
  validation work to testers- be clear to the agent as to which role it is, when you're allocating it a task (to avoid confusion)
- Tasks are expected to be somewhat verified by the allocated "coder", "deployer" or "tester" agent (remaining conscious of small model limitations)
- The "coordinator" agent is ultimately responsible for verifying that a task has been completed correctly and should organise re-work as required

# The "coder" agents only

- The "coordinator" will provide clear directions on development tasks (including how to verify)
- Create a new branch from master, using the task number as a name
- Keep code changes terse but pragmatic; code to move fast in the present without badly forsaking the future
- Let the "coordinator" know when complete; the "coordinator" will further validate and merge the branch (or request changes)
- Ensure not to commit Python `.venv`, JavaScript `node_modules`, Rust `target` etc
- Do not work beyond your task

# The "deployer" agents only

- The "coordinator" will provide clear directions on deployment tasks (including how to verify)
- Deployments to the local environment can be as simple as local, native development servers (just enough to enable external validation)
- Deployments to the target environments are likely to be Kubernetes in the "dev" cluster as per /home/edward/Projects/Home/home-ops
- Let the "coordinator" know when complete; the "coordinator" may further validate and accept the work (or request changes)
- Ensure to exclude Python `.venv`, JavaScript `node_modules`, Rust `target` etc from Docker builds
- Do not work beyond your task

# The "tester" agents only

- The "coordinator" will provide clear directions on testing tasks (including how to verify)
- There are some shared resources that may be useful for testing documented at /home/edward/Projects/Home/home-ops/SERVICES.md
- Testing may be against the local environment or the target environment
- Let the "coordinator" know when complete; the "coordinator" may further validate and accept the results (or request further testing)
- Ensure not to commit jUnit test results etc
- Do not work beyond your task

# All agents

- Never claim a command was run unless the command tool returned its output
- Never claim tests passed unless you actually ran the test command
- Never claim a file or message was changed unless the corresponding tool returned success
- Do not describe an intended tool call as if it already happened
- When an action is required, call the tool immediately
- After every tool call, inspect its result before reporting the outcome

# Reusable services

See `/root/.pi/agent/SERVICES.md` for reusable services
