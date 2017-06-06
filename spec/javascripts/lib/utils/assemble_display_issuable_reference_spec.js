import assembleDisplayIssuableReference from '~/lib/utils/assemble_display_issuable_reference';

describe('assembleDisplayIssuableReference', () => {
  it('should work with only issue number reference', () => {
    expect(assembleDisplayIssuableReference({ iid: 111 }, 'foo', 'bar')).toEqual('#111');
  });
  it('should work with project and issue number reference', () => {
    expect(assembleDisplayIssuableReference({ project_path: 'qux', iid: 111 }, 'foo', 'bar')).toEqual('qux#111');
  });
  it('should work with full reference to current project', () => {
    expect(assembleDisplayIssuableReference({ namespace_full_path: 'foo', project_path: 'garply', iid: 111 }, 'foo', 'bar')).toEqual('garply#111');
  });
  it('should work with sub-groups', () => {
    expect(assembleDisplayIssuableReference({ namespace_full_path: 'some/with/sub/groups', project_path: 'other', iid: 111 }, 'foo', 'bar')).toEqual('some/with/sub/groups/other#111');
  });
  it('does not mangle other group references', () => {
    expect(assembleDisplayIssuableReference({ namespace_full_path: 'some', project_path: 'other', iid: 111 }, 'foo', 'bar')).toEqual('some/other#111');
  });
  it('does not mangle other group even with partial match', () => {
    expect(assembleDisplayIssuableReference({ namespace_full_path: 'bar/baz', project_path: 'fido', iid: 111 }, 'foo/bar/baz', 'garply')).toEqual('bar/baz/fido#111');
  });
});
