package pipes

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPipe(t *testing.T) {
	{
		p := From("a")
		assert.NoError(t, p.Err())

		sl, err := p.Collect()
		assert.NoError(t, err)
		assert.Equal(t, []string{"a"}, sl)
	}

	{
		p := From(0, 1, 2, 3)
		assert.NoError(t, p.Err())
		p = p.Limit(2)
		assert.NoError(t, p.Err())
		sl, err := p.Collect()
		assert.NoError(t, err)
		assert.Equal(t, []int{0, 1}, sl)
	}

	{
		p := From(0, 1, 2, 3)
		assert.NoError(t, p.Err())
		ch := Chunk(p, 2)
		assert.NoError(t, ch.Err())
		sl, err := ch.Collect()
		assert.NoError(t, err)
		assert.Equal(t, [][]int{{0, 1}, {2, 3}}, sl)
	}
}
