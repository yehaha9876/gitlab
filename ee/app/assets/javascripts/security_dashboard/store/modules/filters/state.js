export default () => ({
  filters: [
    {
      name: 'Report type',
      id: 'type',
      options: [
        {
          name: 'All',
          id: 'all',
          selected: true,
        },
        {
          name: 'SAST',
          id: 'sast',
          selected: false,
        },
        {
          name: 'DAST',
          id: 'dast',
          selected: false,
        },
      ],
    },
    {
      name: 'Severity',
      id: 'severity',
      options: [
        {
          name: 'All',
          id: 'all',
          selected: true,
        },
        {
          name: 'Critical',
          id: 'critical',
          selected: false,
        },
      ],
    },
    {
      name: 'Project',
      id: 'project',
      options: [
        {
          name: 'All',
          id: 'all',
          selected: true,
        },
        {
          name: 'Project One',
          id: 'projectOne',
          selected: false,
        },
      ],
    },
  ],
});
