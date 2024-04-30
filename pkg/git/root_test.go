package git

import (
	"testing"

	"github.com/bruin-data/bruin/pkg/path"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRepo(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		path    string
		want    *Repo
		wantErr bool
	}{
		{
			name:    "no repo exists",
			path:    "/",
			wantErr: true,
		},
		{
			name: "can find its own repo root",
			path: ".",
			want: &Repo{
				Path: path.AbsPathForTests(t, "../../."),
			},
		},
		{
			name: "can find its own repo root even if a file is given",
			path: "./root_test.go",
			want: &Repo{
				Path: path.AbsPathForTests(t, "../../."),
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			finder := &RepoFinder{}
			got, err := finder.Repo(tt.path)
			if tt.wantErr {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
			}

			assert.Equal(t, tt.want, got)
		})
	}
}
