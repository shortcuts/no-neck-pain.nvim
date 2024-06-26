cd $1

SINCE=$(git rev-parse --until=2024-04-03)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
HASH=$(git rev-list -1 $SINCE $BRANCH)

echo $1

git reset --hard $HASH
