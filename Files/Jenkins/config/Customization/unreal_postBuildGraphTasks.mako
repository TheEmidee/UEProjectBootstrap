def warnings_files = findFiles glob: 'Saved\\Jenkins\\*.txt'

<%text>def record_issues_id = "BuildGraph_${taskName}".replaceAll('\\s+', '_');</%text>
def quality_gates = [[threshold: 1, type: 'TOTAL', unstable: false], [threshold: 1, type: 'TOTAL_ERROR', unstable: false]]

if ( taskName.contains( "Compile" ) && !taskName.contains( "Blueprints" ) ) {
    recordIssues enabledForFailure: true, failOnError: true, qualityGates : quality_gates, tools: [ msBuild( id: record_issues_id, name: record_issues_id, pattern: 'Saved/Logs/Compile_*.log' ) ]
} else if ( taskName.contains( "Static Analysis" ) ) {
    recordIssues enabledForFailure: true, failOnError: true, qualityGates : quality_gates, tools: [ msBuild( id: record_issues_id, name: record_issues_id, pattern: 'Saved/Logs/StaticAnalysis_*.log' ) ]
}

if ( warnings_files.length > 0 ) {
    recordIssues enabledForFailure: true, failOnError: true, qualityGates : quality_gates, tools: [groovyScript(id: record_issues_id, name: record_issues_id, parserId: 'UE_BuildgraphWarnings', pattern: 'Saved/Jenkins/*.txt')]
    archiveArtifacts artifacts: 'Saved\\Jenkins\\*.txt', followSymlinks: false
}

def functional_tests_results_path = 'Saved\\Tests\\Logs\\FunctionalTestsResults.xml'
if ( fileExists( functional_tests_results_path ) ) {
    junit testResults: functional_tests_results_path
    archiveArtifacts artifacts: 'Saved\\Tests\\Logs\\*.xml', followSymlinks: false
}

archiveArtifacts artifacts: 'Saved\\Logs\\*.log', followSymlinks: false, allowEmptyArchive: true