package base

import (
	"context"
	_ "embed"
	"fmt"

	containerregistry "github.com/google/go-containerregistry/pkg/v1"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/e2b-dev/infra/packages/orchestrator/internal/sandbox/block"
	"github.com/e2b-dev/infra/packages/orchestrator/internal/template/build/buildcontext"
	"github.com/e2b-dev/infra/packages/orchestrator/internal/template/build/config"
	"github.com/e2b-dev/infra/packages/orchestrator/internal/template/build/core/rootfs"
	"github.com/e2b-dev/infra/packages/orchestrator/internal/template/constants"
	artifactsregistry "github.com/e2b-dev/infra/packages/shared/pkg/artifacts-registry"
	"github.com/e2b-dev/infra/packages/shared/pkg/dockerhub"
)

func constructLayerFilesFromOCI(
	ctx context.Context,
	userLogger *zap.Logger,
	buildContext buildcontext.BuildContext,
	// The base build ID can be different from the final requested template build ID.
	baseBuildID string,
	artifactRegistry artifactsregistry.ArtifactsRegistry,
	dockerhubRepository dockerhub.RemoteRepository,
	rootfsPath string,
) (r *block.Local, m block.ReadonlyDevice, c containerregistry.Config, e error) {
	childCtx, childSpan := tracer.Start(ctx, "template-build")
	defer childSpan.End()

	// Create a rootfs file
	rtfs := rootfs.New(
		artifactRegistry,
		dockerhubRepository,
		buildContext.Template,
		buildContext.Config,
	)
	// 禁用代理：代理服务器不可用（504 错误）
	// 让 VM 直接访问网络
	httpProxy := ""
	httpsProxy := ""

	// 调试日志
	userLogger.Info("Provision script proxy configuration (proxy disabled due to 504 errors)",
		zap.String("HTTP_PROXY", httpProxy),
		zap.String("HTTPS_PROXY", httpsProxy),
	)

	provisionScript, err := getProvisionScript(ctx, ProvisionScriptParams{
		BusyBox:    "/" + rootfs.BusyBoxPath,
		ResultPath: provisionScriptResultPath,
		HTTPProxy:  httpProxy,
		HTTPSProxy: httpsProxy,
	})
	if err != nil {
		return nil, nil, containerregistry.Config{}, fmt.Errorf("error getting provision script: %w", err)
	}
	imgConfig, err := rtfs.CreateExt4Filesystem(childCtx, userLogger, rootfsPath, provisionScript, provisionLogPrefix)
	if err != nil {
		return nil, nil, containerregistry.Config{}, fmt.Errorf("error creating ext4 filesystem: %w", err)
	}

	buildIDParsed, err := uuid.Parse(baseBuildID)
	if err != nil {
		return nil, nil, containerregistry.Config{}, fmt.Errorf("failed to parse build id: %w", err)
	}

	rootfs, err := block.NewLocal(rootfsPath, buildContext.Config.RootfsBlockSize(), buildIDParsed)
	if err != nil {
		return nil, nil, containerregistry.Config{}, fmt.Errorf("error reading rootfs blocks: %w", err)
	}

	// Create empty memfile
	memfile, err := block.NewEmpty(
		buildContext.Config.MemoryMB<<constants.ToMBShift,
		config.MemfilePageSize(buildContext.Config.HugePages),
		buildIDParsed,
	)
	if err != nil {
		return nil, nil, containerregistry.Config{}, fmt.Errorf("error creating memfile: %w", err)
	}

	return rootfs, memfile, imgConfig, nil
}
