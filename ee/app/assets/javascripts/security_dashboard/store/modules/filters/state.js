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
  ],
});
