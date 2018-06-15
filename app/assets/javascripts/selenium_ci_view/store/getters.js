export const firstSessionId = (state, getters) => {
  return state.sessionIds[0];
};

export const firstSessionLogEntry = (state, getters) => {
  return state.sessionLog.gitlab[0]
}
