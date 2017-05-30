import {
  ISSUABLE_REFERENCE_REGEX,
  ISSUABLE_URL_REGEX,
  assembleDisplayIssuableReference,
} from '~/lib/utils/issuable_reference_utils';

describe('issuable_reference_utils', () => {
  describe('ISSUABLE_REFERENCE_REGEX', () => {
    it('should match reference with only issue number with hash', () => {
      expect(ISSUABLE_REFERENCE_REGEX.test('#123')).toEqual(true);
    });
    it('should match reference with project preceding issue number with hash', () => {
      expect(ISSUABLE_REFERENCE_REGEX.test('bar#123')).toEqual(true);
    });
    it('should match full reference with namespace', () => {
      expect(ISSUABLE_REFERENCE_REGEX.test('foo/bar#123')).toEqual(true);
    });
    it('should match nested group namespaces', () => {
      expect(ISSUABLE_REFERENCE_REGEX.test('foo/bar/baz/qux#123')).toEqual(true);
    });

    it('should not match if missing hash', () => {
      expect(ISSUABLE_REFERENCE_REGEX.test('123')).toEqual(false);
    });
    it('should not match if trailing slash on project', () => {
      expect(ISSUABLE_REFERENCE_REGEX.test('foo/#123')).toEqual(false);
    });
    it('should not match project path', () => {
      expect(ISSUABLE_REFERENCE_REGEX.test('foo/bar')).toEqual(false);
    });
  });

  describe('ISSUABLE_URL_REGEX', () => {
    it('should match full URL to GitLab.com', () => {
      expect(ISSUABLE_URL_REGEX.test('https://gitlab.com/gitlab-org/gitlab-ee/issues/2001')).toEqual(true);
    });
    it('should match full URL to GitLab.com with trailing slash', () => {
      expect(ISSUABLE_URL_REGEX.test('https://gitlab.com/gitlab-org/gitlab-ee/issues/2001/')).toEqual(true);
    });
    it('should match url without any protocol', () => {
      expect(ISSUABLE_URL_REGEX.test('gitlab.com/gitlab-org/gitlab-ee/issues/2001')).toEqual(true);
    });
    it('should match protocol-relative URL', () => {
      expect(ISSUABLE_URL_REGEX.test('//gitlab.com/gitlab-org/gitlab-ee/issues/2001')).toEqual(true);
    });
    it('should match localhost (no tld)', () => {
      expect(ISSUABLE_URL_REGEX.test('localhost/gitlab-org/gitlab-ee/issues/2001')).toEqual(true);
    });
    it('should match localhost with a port (no tld)', () => {
      expect(ISSUABLE_URL_REGEX.test('localhost:3000/gitlab-org/gitlab-ee/issues/2001')).toEqual(true);
    });

    it('should not match full reference', () => {
      expect(ISSUABLE_URL_REGEX.test('foo/bar#123')).toEqual(false);
    });
    it('should not match project path', () => {
      expect(ISSUABLE_URL_REGEX.test('foo/bar')).toEqual(false);
    });
    it('should not match string with numbers in it', () => {
      expect(ISSUABLE_URL_REGEX.test('somethingwith123inthemiddle')).toEqual(false);
    });
  });

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
});
