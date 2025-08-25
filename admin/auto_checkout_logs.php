<?php
require_once '../config/database.php';

// Get checkout logs with pagination
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = 20;
$offset = ($page - 1) * $limit;

$stmt = $pdo->prepare("
    SELECT l.*, r.room_type 
    FROM auto_checkout_logs l
    LEFT JOIN rooms r ON l.room_id = r.id
    ORDER BY l.created_at DESC
    LIMIT ? OFFSET ?
");
$stmt->execute([$limit, $offset]);
$logs = $stmt->fetchAll();

// Get total count for pagination
$countStmt = $pdo->query("SELECT COUNT(*) FROM auto_checkout_logs");
$totalLogs = $countStmt->fetchColumn();
$totalPages = ceil($totalLogs / $limit);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Auto Checkout Logs - Hotel System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="container-fluid py-4">
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h1><i class="fas fa-history me-2"></i>Auto Checkout Logs</h1>
                    <a href="rooms.php" class="btn btn-primary">
                        <i class="fas fa-arrow-left me-1"></i>Back to Rooms
                    </a>
                </div>

                <div class="card">
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-striped">
                                <thead>
                                    <tr>
                                        <th>Date & Time</th>
                                        <th>Room</th>
                                        <th>Guest Name</th>
                                        <th>Status</th>
                                        <th>Notes</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php if (empty($logs)): ?>
                                        <tr>
                                            <td colspan="5" class="text-center py-4">
                                                <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                                                <p class="text-muted">No auto checkout logs found</p>
                                            </td>
                                        </tr>
                                    <?php else: ?>
                                        <?php foreach ($logs as $log): ?>
                                            <tr>
                                                <td>
                                                    <?php echo date('M d, Y H:i', strtotime($log['created_at'])); ?>
                                                </td>
                                                <td>
                                                    <strong><?php echo $log['room_number']; ?></strong>
                                                    <?php if ($log['room_type']): ?>
                                                        <br><small class="text-muted"><?php echo $log['room_type']; ?></small>
                                                    <?php endif; ?>
                                                </td>
                                                <td><?php echo $log['guest_name'] ?: '-'; ?></td>
                                                <td>
                                                    <span class="badge bg-<?php echo $log['status'] === 'success' ? 'success' : 'danger'; ?>">
                                                        <i class="fas fa-<?php echo $log['status'] === 'success' ? 'check' : 'times'; ?> me-1"></i>
                                                        <?php echo ucfirst($log['status']); ?>
                                                    </span>
                                                </td>
                                                <td><?php echo $log['notes'] ?: '-'; ?></td>
                                            </tr>
                                        <?php endforeach; ?>
                                    <?php endif; ?>
                                </tbody>
                            </table>
                        </div>

                        <?php if ($totalPages > 1): ?>
                            <nav aria-label="Logs pagination">
                                <ul class="pagination justify-content-center">
                                    <?php if ($page > 1): ?>
                                        <li class="page-item">
                                            <a class="page-link" href="?page=<?php echo $page - 1; ?>">Previous</a>
                                        </li>
                                    <?php endif; ?>

                                    <?php for ($i = 1; $i <= $totalPages; $i++): ?>
                                        <li class="page-item <?php echo $i === $page ? 'active' : ''; ?>">
                                            <a class="page-link" href="?page=<?php echo $i; ?>"><?php echo $i; ?></a>
                                        </li>
                                    <?php endfor; ?>

                                    <?php if ($page < $totalPages): ?>
                                        <li class="page-item">
                                            <a class="page-link" href="?page=<?php echo $page + 1; ?>">Next</a>
                                        </li>
                                    <?php endif; ?>
                                </ul>
                            </nav>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>