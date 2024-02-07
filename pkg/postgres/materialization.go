package postgres

import (
	"fmt"
	"strings"

	"github.com/bruin-data/bruin/pkg/helpers"
	"github.com/bruin-data/bruin/pkg/pipeline"
)

type randomSuffixGenerator func() string

type Materializer struct {
	prefixGenerator randomSuffixGenerator
}

func NewMaterializer() *Materializer {
	return &Materializer{
		prefixGenerator: helpers.PrefixGenerator,
	}
}

func (m Materializer) Render(task *pipeline.Asset, query string) (string, error) {
	mat := task.Materialization
	if mat.Type == pipeline.MaterializationTypeNone {
		return query, nil
	}

	if mat.Type == pipeline.MaterializationTypeView {
		return fmt.Sprintf("CREATE OR REPLACE VIEW %s AS\n%s", task.Name, query), nil
	}

	if mat.Type == pipeline.MaterializationTypeTable {
		strategy := mat.Strategy
		if strategy == pipeline.MaterializationStrategyNone {
			strategy = pipeline.MaterializationStrategyCreateReplace
		}

		if strategy == pipeline.MaterializationStrategyAppend {
			return fmt.Sprintf("INSERT INTO %s %s", task.Name, query), nil
		}

		if strategy == pipeline.MaterializationStrategyCreateReplace {
			return buildCreateReplaceQuery(task, query)
		}

		if strategy == pipeline.MaterializationStrategyDeleteInsert {
			return m.buildIncrementalQuery(task, query, mat, strategy)
		}
	}

	return "", fmt.Errorf("unsupported materialization type - strategy combination: (`%s` - `%s`)", mat.Type, mat.Strategy)
}

func (m *Materializer) buildIncrementalQuery(task *pipeline.Asset, query string, mat pipeline.Materialization, strategy pipeline.MaterializationStrategy) (string, error) {
	if mat.IncrementalKey == "" {
		return "", fmt.Errorf("materialization strategy %s requires the `incremental_key` field to be set", strategy)
	}

	tempTableName := fmt.Sprintf("__bruin_tmp_%s", m.prefixGenerator())

	queries := []string{
		"BEGIN TRANSACTION",
		fmt.Sprintf("CREATE TEMP TABLE %s AS %s", tempTableName, query),
		fmt.Sprintf("DELETE FROM %s WHERE %s in (SELECT DISTINCT %s FROM %s)", task.Name, mat.IncrementalKey, mat.IncrementalKey, tempTableName),
		fmt.Sprintf("INSERT INTO %s SELECT * FROM %s", task.Name, tempTableName),
		fmt.Sprintf("DROP TABLE IF EXISTS %s", tempTableName),
		"COMMIT",
	}

	return strings.Join(queries, ";\n") + ";", nil
}

func buildCreateReplaceQuery(task *pipeline.Asset, query string) (string, error) {
	query = strings.TrimSuffix(query, ";")
	return fmt.Sprintf(
		`BEGIN TRANSACTION;
DROP TABLE IF EXISTS %s; 
CREATE TABLE %s AS %s;
COMMIT;`, task.Name, task.Name, query), nil
}