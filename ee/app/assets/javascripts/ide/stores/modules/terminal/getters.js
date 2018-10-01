export const environmentCheck = state => {
  const checks = [
    state.configCheck,
    state.runnersCheck,
  ];

  if (checks.some(check => check.isLoading)) {
    return { isLoading: true };
  }

  const invalidCheck = checks.find(check => !check.isValid);

  return {
    isLoading: false,
    isValid: !invalidCheck,
    message: invalidCheck && invalidCheck.message,
  };
};

export default () => {};
