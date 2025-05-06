# This script sets branch protection rules for a GitHub repository using the GitHub CLI.
# It requires the repository owner and name as input parameters.
# https://github.com/cli/cli/issues/3528#issuecomment-926930511
owner="YourOrgName"
name="YourRepoName"
repositoryId="$(gh api graphql -f query='{repository(owner:"'$owner'",name:"'$name'"){id}}' -q .data.repository.id)"

gh api graphql -f query='
mutation($repositoryId:ID!,$branch:String!,$requiredReviews:Int!) {
  createBranchProtectionRule(input: {
    repositoryId: $repositoryId
    pattern: $branch
    requiresApprovingReviews: true
    requiredApprovingReviewCount: $requiredReviews
  }) { clientMutationId }
}' -f repositoryId="$repositoryId" -f branch="main" -F requiredReviews=1
