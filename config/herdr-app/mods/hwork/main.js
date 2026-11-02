import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, Select, Popup } from "gpui-base";
import { focused, spaces, knownAgents, exec, home, props, closeOverlay, theme, shared, setShared } from "herdr";

export default class Hwork extends View {
  init(_props, cx) {
    const target = focused();
    const space = spaces().find(s => s.id === target?.space);
    this.folder = target?.cwd || space?.folder;
    this.parent = space?.id ?? "";
    this.error = space?.machine ? "Select a local Space to create a worktree." : "";
    this.blocked = Boolean(space?.machine);
    this.busy = false;
    this.agents = [];
    this.agent = null;
    this.loading = true;
    this.pickers = {};
    for (const id of ["agent", "parent"]) this.pickers[id] = {
      open: false, at: 0, trigger: cx.focus_handle(), content: cx.focus_handle(),
    };
    this.input = InputState.new({ placeholder: "fix-search" });
    this.input.on("submit", (_event, cx) => this.submit(cx));
    this.input.focus();
    cx.timer.after(100, () => this.input.focus());
    cx.spawn(async cx => {
      try {
        this.agents = (await knownAgents()).filter(a => a.installed);
        this.agent = this.agents.find(a => a.key === "pi" || a.run[0] === "pi") ?? this.agents[0] ?? null;
        if (!this.agent) this.error = "No installed agents found.";
      } catch (error) { this.error = `Could not load agents: ${error}`; }
      this.loading = false;
      cx.notify();
    });
  }

  submit(cx) {
    if (this.busy || this.blocked || !this.agent) return;
    const name = this.input.value().trim();
    if (!/^[a-z][a-z0-9_-]{0,31}$/.test(name)) {
      this.error = "Use 1–32 lowercase letters, digits, _ or -, starting with a letter.";
      cx.notify();
      return;
    }
    if (this.parent && !spaces().some(s => s.id === this.parent && !s.machine)) {
      this.error = "The selected parent Space is no longer available.";
      cx.notify();
      return;
    }
    const parent = this.parent || null;
    const argv = [...this.agent.run];
    this.busy = true;
    this.error = "";
    cx.notify();
    cx.spawn(async cx => {
      try {
        const result = await exec(`${home()}/.local/bin/hwork`, [name, "--agent-argv", JSON.stringify(argv)], { cwd: this.folder });
        if (result.code !== 0) throw new Error(result.stderr || result.stdout || "Could not create the worktree.");
        const created = JSON.parse(result.stdout);
        if (!created.space) throw new Error("The launcher did not return the new Space ID.");
        setShared("hwork.parents", { ...(shared("hwork.parents") ?? {}), [created.space]: parent });
        closeOverlay(props().overlay);
      } catch (error) { this.error = String(error); }
      this.busy = false;
      cx.notify();
    });
  }

  picker(id, label, options, value, choose) {
    const t = theme(), state = this.pickers[id];
    const selected = options.find(o => o.value === value);
    const changeOpen = (open, cx) => {
      if (this.busy) return;
      for (const other of Object.values(this.pickers)) other.open = false;
      state.open = open;
      state.at = Math.max(0, options.findIndex(o => o.value === value));
      cx.notify();
    };
    const pick = (i, cx) => {
      if (!options[i] || this.busy) return;
      choose(options[i].value);
      state.open = false;
      state.trigger.focus();
      cx.notify();
    };
    const trigger = h_flex().id(`${id}-trigger`).h(36).px(10).gap(8).items_center()
      .rounded(6).border_1().border_color(t.input).bg(t.background)
      .cursor_pointer().on_click((_e, cx) => changeOpen(!state.open, cx))
      .child(div().flex_1().truncate().child(selected?.label ?? (this.loading ? "Checking installed agents…" : "No agents available")))
      .child(div().text_color(t.dim).child("▾"));
    const list = v_flex().id(`${id}-list`).w(440).max_h(180).p(4).gap(2)
      .bg(t.popover).border_1().border_color(t.border).rounded(6)
      .overflow_y_scrollbar().track_focus(state.content)
      .on_key_down((event, cx) => {
        if (["up", "down"].includes(event.key) && options.length) {
          state.at = (state.at + (event.key === "down" ? 1 : options.length - 1)) % options.length;
        } else if (event.key === "enter") pick(state.at, cx);
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .children(options.map((option, i) => div().id(`${id}-${i}`).role("list_box_option")
        .when(i === state.at, el => el.aria_active_descendant().bg(t.selected))
        .px(8).py(7).rounded(4).cursor_pointer()
        .hover(el => el.bg(t.hover)).on_click((_e, cx) => pick(i, cx))
        .child(option.label)));
    return v_flex().gap(6)
      .child(div().text_size(11.5).text_color(t.muted).child(label))
      .child(Select.new(id).accessibility_label(label).open(state.open)
        .track_focus(state.trigger).content_focus_handle(state.content)
        .on_open_change(changeOpen)
        .child(Popup.new(`${id}-popup`, trigger).when(state.open, el => el.content(list))));
  }

  render() {
    const t = theme();
    const parents = [{ value: "", label: "Top level" }, ...spaces().filter(s => !s.machine)
      .map(s => ({ value: s.id, label: s.name }))];
    return v_flex().id("hwork").size_full().p(18).gap(12)
      .bg(t.popover).text_color(t.foreground).text_size(13)
      .child(div().font_semibold().child("New worktree"))
      .child(v_flex().gap(6)
        .child(div().text_size(11.5).text_color(t.muted).child("Name"))
        .child(Input.new(this.input).h(36).px(10).rounded(6).border_1().border_color(t.accent).bg(t.background)))
      .child(this.picker("agent", "Agent", this.agents.map(a => ({ value: a.key, label: a.name })), this.agent?.key,
        key => { this.agent = this.agents.find(a => a.key === key); }))
      .child(this.picker("parent", "Place under", parents, this.parent, id => { this.parent = id; }))
      .when(Boolean(this.error), el => el.child(div().text_color(t.blocked).child(this.error)))
      .child(h_flex().items_center().gap(10)
        .child(div().flex_1().text_size(11.5).text_color(t.dim).child("Esc to cancel"))
        .child(div().id("create-worktree").px(12).py(8).rounded(6)
          .bg(t.solid).text_color(t.solid_foreground).cursor_pointer()
          .when(this.busy || !this.agent || this.blocked, el => el.opacity(0.5))
          .on_click((_event, cx) => this.submit(cx))
          .child(this.busy ? "Creating…" : "Create worktree")));
  }
}
