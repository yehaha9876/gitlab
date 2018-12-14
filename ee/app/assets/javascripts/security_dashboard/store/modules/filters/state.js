export default () => ({
  filters: [
    {
      name: 'Report type',
      id: 'type',
      options: [
        {
          name: 'All',
          id: '',
          selected: true,
        },
        {
          name: 'SAST',
          id: '0',
          selected: false,
        },
        {
          name: 'DAST',
          id: '1',
          selected: false,
        },
      ],
    },
  ],
});
